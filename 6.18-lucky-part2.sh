#!/bin/bash
# ==============================================================================
# 6.18-lucky 专属独立 Part 2 编译脚本（完全独立，不共用 common-proxy-verification.sh 与 files/）
# ==============================================================================
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

target_kernel_series="6.18"
target_default_ip="192.168.0.245"
target_hostname="EAY-LUCKY"

verify_lucky_stack() {
    echo ""
    echo "=== Verifying LUCKY standalone package stack ==="

    rm -rf package/feeds/luci/luci-app-argon-config feeds/luci/applications/luci-app-argon-config package/luci-app-argon-config 2>/dev/null || true
    rm -rf package/feeds/luci/luci-theme-argon feeds/luci/themes/luci-theme-argon 2>/dev/null || true
    sed -i '/CONFIG_PACKAGE_luci-app-argon-config=/d' .config 2>/dev/null || true
    echo "# CONFIG_PACKAGE_luci-app-argon-config is not set" >> .config

    grep -q '^CONFIG_PACKAGE_lucky=y' .config || { echo "ERROR: lucky is disabled in .config"; exit 1; }
    grep -q '^CONFIG_PACKAGE_luci-app-lucky=y' .config || { echo "ERROR: luci-app-lucky is disabled in .config"; exit 1; }
    [ -d "package/lucky" ] || { echo "ERROR: Lucky package source not found in package/lucky"; exit 1; }

    local forbidden_pkgs=(
        "CONFIG_PACKAGE_luci-app-homeproxy"
        "CONFIG_PACKAGE_sing-box"
        "CONFIG_PACKAGE_smartdns"
        "CONFIG_PACKAGE_luci-app-smartdns"
        "CONFIG_PACKAGE_luci-app-sqm"
        "CONFIG_PACKAGE_sqm-scripts"
        "CONFIG_PACKAGE_luci-app-upnp"
        "CONFIG_PACKAGE_miniupnpd"
        "CONFIG_PACKAGE_luci-app-wol"
        "CONFIG_PACKAGE_etherwake"
    )

    for pkg in "${forbidden_pkgs[@]}"; do
        if grep -q "^${pkg}=y" .config; then
            echo "ERROR: ${pkg} should be disabled in LUCKY build, but is enabled!"
            exit 1
        fi
    done

    echo "LUCKY standalone stack verified successfully."
}

config_is_enabled() {
    local key="$1"

    grep -q "^${key}=y$" .config 2>/dev/null
}

join_by_comma() {
    local joined=""
    local item

    for item in "$@"; do
        [ -n "$item" ] || continue

        if [ -n "$joined" ]; then
            joined="${joined}, ${item}"
        else
            joined="${item}"
        fi
    done

    printf '%s\n' "${joined:-none detected}"
}

to_title_case() {
    local value="$1"

    echo "$value" | tr '-' ' ' | awk '{
        for (i = 1; i <= NF; i++) {
            $i = toupper(substr($i, 1, 1)) substr($i, 2)
        }
        print
    }'
}

detect_kernel_version() {
    local patchver
    local kernel_file
    local kernel_pattern
    local kernel_version

    patchver="$(sed -n 's/^KERNEL_PATCHVER:=//p' target/linux/x86/Makefile | head -n 1 | tr -d '\r')"
    [ -n "$patchver" ] || patchver="$target_kernel_series"

    kernel_file="include/kernel-${patchver}"
    [ ! -f "$kernel_file" ] && kernel_file="target/linux/generic/kernel-${patchver}"
    kernel_pattern="${patchver//./\\.}"
    kernel_version=""

    if [ -f "$kernel_file" ]; then
        kernel_version="$(sed -n "s/^LINUX_VERSION-${kernel_pattern}[[:space:]]*[:?]?=[[:space:]]*//p" "$kernel_file" | head -n 1 | tr -d '\r')"
    fi

    case "$kernel_version" in
        "")
            echo "$patchver"
            ;;
        .*)
            echo "${patchver}${kernel_version}"
            ;;
        [0-9]*)
            echo "${patchver}.${kernel_version}"
            ;;
        *)
            echo "$kernel_version"
            ;;
    esac
}

detect_default_ip() {
    local ip=""

    if [ -f "files/etc/config/network" ]; then
        ip="$(sed -n "s/.*option ipaddr '\([^']*\)'.*/\1/p" files/etc/config/network 2>/dev/null | head -n 1)"
    fi
    if [ -z "$ip" ]; then
        ip="$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' package/base-files/files/bin/config_generate 2>/dev/null | grep -v '^127\.' | head -n 1 || true)"
    fi
    echo "${ip:-unknown}"
}

detect_hostname() {
    local hostname

    hostname="$(sed -n "s/.*hostname='\([^']*\)'.*/\1/p" package/base-files/files/bin/config_generate 2>/dev/null | tail -n 1)"
    echo "${hostname:-unknown}"
}

detect_theme() {
    local theme_pkg

    theme_pkg="$(grep -oE '^CONFIG_PACKAGE_luci-theme-[^=]+=y$' .config 2>/dev/null | head -n 1 | sed -E 's/^CONFIG_PACKAGE_(luci-theme-[^=]+)=y$/\1/' || true)"

    if [ -z "$theme_pkg" ] && [ -f feeds/luci/collections/luci/Makefile ]; then
        theme_pkg="$(grep -oE 'luci-theme-[a-zA-Z0-9_-]+' feeds/luci/collections/luci/Makefile 2>/dev/null | head -n 1 || true)"
    fi

    if [ -z "$theme_pkg" ]; then
        echo "unknown"
        return
    fi

    to_title_case "${theme_pkg#luci-theme-}"
}

detect_performance_tuning() {
    local items=()

    config_is_enabled CONFIG_PACKAGE_kmod-tcp-bbr && items+=("BBR")
    config_is_enabled CONFIG_PACKAGE_kmod-crypto-aes && items+=("AES-NI Acceleration")
    config_is_enabled CONFIG_PACKAGE_kmod-nft-offload && items+=("NFT Flow-Offload")
    config_is_enabled CONFIG_PACKAGE_kmod-nft-nat && items+=("FullCone NAT")
    items+=("1M Conntrack Table")

    join_by_comma "${items[@]}"
}

detect_enabled_apps() {
    local apps=()

    config_is_enabled CONFIG_PACKAGE_lucky && apps+=("Lucky Core")
    config_is_enabled CONFIG_PACKAGE_luci-app-lucky && apps+=("Lucky Web UI (luci-app-lucky)")

    join_by_comma "${apps[@]}"
}

echo "Applying basic settings for 6.18 LUCKY..."

sed -i "s/192\\.168\\.1\\.1/${target_default_ip}/g" package/base-files/files/bin/config_generate
sed -i "s/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=${target_kernel_series}/g" target/linux/x86/Makefile

# 同步更新覆盖目录 files/etc/config/network 中的默认 IP (如果存在覆盖配置)
if [ -f "files/etc/config/network" ]; then
    sed -i "s/option ipaddr .*/option ipaddr '${target_default_ip}'/g" files/etc/config/network
fi

# 清理从通用 files/ 继承的非 LUCKY 专有插件配置 (如 SmartDNS、UPnP、软路由分流脚本等)
rm -f files/etc/uci-defaults/99-system-performance 2>/dev/null || true
rm -f files/etc/init.d/dns-preload 2>/dev/null || true
rm -f files/etc/config/smartdns 2>/dev/null || true
rm -f files/etc/config/upnpd 2>/dev/null || true

# Lucky 专属：保留 files/etc/init.d/performance-mode 的 CPU 满血调度、RPS/XPS 与网卡卸载优化，
# 但移除其中的 disable_ipv6=1，确保 Lucky 的公网 IPv6 DDNS、STUN 穿透与 IPv6 反向代理 100% 正常工作
if [ -f "files/etc/init.d/performance-mode" ]; then
    sed -i '/disable_ipv6=1/d' files/etc/init.d/performance-mode
fi

# 清空默认密码
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/emortal/default-settings/files/99-default-settings 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i "s/hostname='ImmortalWrt'/hostname='${target_hostname}'/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='OpenWrt'/hostname='${target_hostname}'/g" package/base-files/files/bin/config_generate
sed -i "s/option lang 'auto'/option lang 'zh_cn'/g" feeds/luci/modules/luci-base/root/etc/config/luci 2>/dev/null || true
sed -i "s/option lang 'auto'/option lang 'zh_cn'/g" package/feeds/luci/luci-base/root/etc/config/luci 2>/dev/null || true

# 固化系统默认时区为中国上海时间 (CST-8, Asia/Shanghai) 与国内高速 NTP 授时服务
sed -i "s/timezone='UTC'/timezone='CST-8'/g" package/base-files/files/bin/config_generate
sed -i "s/zonename='UTC'/zonename='Asia\/Shanghai'/g" package/base-files/files/bin/config_generate
sed -i "s/'0.openwrt.pool.ntp.org'/'ntp.aliyun.com'/g" package/base-files/files/bin/config_generate 2>/dev/null || true
sed -i "s/'1.openwrt.pool.ntp.org'/'time1.cloud.tencent.com'/g" package/base-files/files/bin/config_generate 2>/dev/null || true
sed -i "s/'2.openwrt.pool.ntp.org'/'time.apple.com'/g" package/base-files/files/bin/config_generate 2>/dev/null || true
sed -i "s/'3.openwrt.pool.ntp.org'/'time.windows.com'/g" package/base-files/files/bin/config_generate 2>/dev/null || true
sed -i "s/timezone='UTC'/timezone='CST-8'/g" package/emortal/default-settings/files/99-default-settings 2>/dev/null || true
sed -i "s/zonename='UTC'/zonename='Asia\/Shanghai'/g" package/emortal/default-settings/files/99-default-settings 2>/dev/null || true

# 启用亚洲时区数据包支持
echo "CONFIG_PACKAGE_zoneinfo-core=y" >> .config
echo "CONFIG_PACKAGE_zoneinfo-asia=y" >> .config

# 彻底重置 openwrt/files 并仅从专属目录 lucky-files/ 复制，做到与其它固件 100% 物理隔离
rm -rf files
mkdir -p files/etc/sysctl.d files/etc/uci-defaults
if [ -d "${script_dir}/lucky-files" ]; then
    cp -a "${script_dir}/lucky-files/." files/
    chmod +x files/etc/init.d/performance-mode files/usr/bin/openwrt-diag 2>/dev/null || true
    echo "Loaded isolated rootfs overlay from lucky-files/."
fi

# 注入针对外网访问内网服务的专属内核与网络优化

cat << 'EOF' > files/etc/sysctl.d/99-lucky-inbound.conf
# ==============================================================================
# Linux 6.18 LUCKY Dedicated Inbound / Reverse Proxy Tuning
# ==============================================================================
# 1. 100万级并发连接跟踪与 2 小时大文件长效连接保持（杜绝大文件下载中途断流）
net.netfilter.nf_conntrack_max = 1048576
net.netfilter.nf_conntrack_acct = 0
net.netfilter.nf_conntrack_tcp_be_liberal = 1
net.netfilter.nf_conntrack_tcp_timeout_established = 7200
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 15
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 15
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 15

# 2. 扩充本地临时端口范围（5.5万端口），防止 40+ 反向代理高并发时本地端口耗尽报错
net.ipv4.ip_local_port_range = 10240 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10

# 3. TCP BBR + FQ 拥塞控制 + 被动 ECN/DSACK，跨公网/4G/5G 高丢包环境下保障大文件满速
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_ecn = 2
net.ipv4.tcp_ecn_fallback = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_comp_sack = 1

# 4. Linux 6.18 原生 UDP GRO 转发加速与 UDP 最小缓冲（加速 QUIC / HTTP3 / STUN 穿透）
net.ipv4.udp_gro_forwarding = 1
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.core.optmem_max = 131072
net.ipv4.ip_forward = 1

# 5. 握手与并发连接队列优化（禁用小包攒包延迟，首包零等待）
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_autocorking = 0
net.ipv4.tcp_no_metrics_save = 1
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 16384
net.core.netdev_max_backlog = 32768

# 6. 64MB 高 BDP 动态 TCP 缓冲区（极大提升跨省/公网大文件双向拉取/上传带宽利用率，256KB 初始默认窗口起步即满速）
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_rmem = 4096 262144 67108864
net.ipv4.tcp_wmem = 4096 262144 67108864
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864

# 外网高速上传防拥堵：调大 NAPI 轮询与协议栈数据包递交预算，杜绝突发接收丢包
net.core.netdev_budget = 600
net.core.netdev_budget_usecs = 8000

# 平衡虚拟内存脏页回写，防止大文件持续上传内网落地时 I/O 阻塞系统
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5

# 7. FileBrowser / WebDAV / Emby 大文件双向传输专属优化 (解决断流、超时与 MTU 黑洞卡死)
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_base_mss = 1024
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5

# 扩充系统全局文件句柄至 200 万，完美支撑多线程分块并发下载/上传与多反代端口
fs.file-max = 2097152
fs.nr_open = 2097152

# 8. 独立应用主机模式：保留 IPv6 双栈直连入站，关闭 ICMP 重定向，放宽反向路径校验 (Loose Mode)
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2

# 9. 独立主机暴露高位端口下的安全防扫描、抗 SYN 泛洪与无人值守崩溃自愈
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
kernel.panic = 10
kernel.panic_on_oops = 1
EOF

# 注入独立应用主机防火墙、服务保护与定时守护默认设置
cat << 'EOF' > files/etc/uci-defaults/99-lucky-appliance
#!/bin/sh
if ! uci -q show network.globals >/dev/null 2>&1; then
    uci set network.globals='globals'
fi
# 关闭 OpenWrt 原生 packet_steering，防止将多队列网卡全部挤向 CPU0；由 performance-mode 自动管理多核 RSS/XPS
uci -q set network.globals.packet_steering='0'
uci -q commit network

# 1. 独立主机纯净模式：彻底关闭本机的 DHCP 服务，严禁抢答局域网主路由的 DHCP 分配导致冲突
if uci -q get dhcp.lan >/dev/null 2>&1; then
    uci -q set dhcp.lan.ignore='1'
    uci -q commit dhcp
fi

# 2. 清理不存在的 127.0.0.1#5333 死上游，扩容本地 DNS 缓存与并发上限，保障 Lucky DDNS/ACME 毫秒级响应
if uci -q get dhcp.@dnsmasq[0] >/dev/null 2>&1; then
    uci -q del dhcp.@dnsmasq[0].server 2>/dev/null || true
    uci -q add_list dhcp.@dnsmasq[0].server='223.5.5.5'
    uci -q add_list dhcp.@dnsmasq[0].server='119.29.29.29'
    uci -q set dhcp.@dnsmasq[0].cachesize='10000'
    uci -q set dhcp.@dnsmasq[0].dnsforwardmax='1024'
    uci -q set dhcp.@dnsmasq[0].min_cache_ttl='60'
    uci -q commit dhcp
fi

# 3. 独立主机入站全放行：确保主路由映射的高位端口与 Lucky 管理后台畅通无阻
if uci -q get firewall.@zone[0] >/dev/null 2>&1; then
    uci -q set firewall.@zone[0].input='ACCEPT'
    uci -q set firewall.@zone[0].output='ACCEPT'
    uci -q set firewall.@zone[0].forward='ACCEPT'
    uci -q commit firewall
fi

# 4. 开启底层 Flow Offloading 流量加速
if uci -q get firewall.@defaults[0] >/dev/null 2>&1; then
    uci -q set firewall.@defaults[0].flow_offloading='1'
    uci -q set firewall.@defaults[0].flow_offloading_hw='0'
    uci -q set firewall.@defaults[0].forward='ACCEPT'
    uci -q set firewall.@defaults[0].syn_flood='0'
    uci -q commit firewall
fi

# 5. 设置系统时区为中国上海时间 (CST-8, Asia/Shanghai) 并配置国内高可用 NTP 授时服务，限制日志内存占用
if uci -q get system.@system[0] >/dev/null 2>&1; then
    uci -q set system.@system[0].timezone='CST-8'
    uci -q set system.@system[0].zonename='Asia/Shanghai'
    uci -q set system.@system[0].log_size='512'
    uci -q set system.@system[0].log_buffer_size='512'
    uci -q set system.@system[0].conloglevel='4'
    uci -q set system.@system[0].cronloglevel='8'
    uci -q commit system
fi

if uci -q get system.ntp >/dev/null 2>&1; then
    uci -q del system.ntp.server 2>/dev/null || true
    uci -q add_list system.ntp.server='ntp.aliyun.com'
    uci -q add_list system.ntp.server='time1.cloud.tencent.com'
    uci -q add_list system.ntp.server='time.apple.com'
    uci -q add_list system.ntp.server='time.windows.com'
    uci -q commit system
fi

echo "CST-8" > /etc/TZ 2>/dev/null || true

if [ -x /etc/init.d/performance-mode ]; then
    /etc/init.d/performance-mode enable >/dev/null 2>&1 || true
    /etc/init.d/performance-mode restart >/dev/null 2>&1 || /etc/init.d/performance-mode start >/dev/null 2>&1 || true
fi

if [ -x /etc/init.d/irqbalance ]; then
    /etc/init.d/irqbalance enable >/dev/null 2>&1 || true
    /etc/init.d/irqbalance restart >/dev/null 2>&1 || /etc/init.d/irqbalance start >/dev/null 2>&1 || true
fi

# 6. 调大进程打开文件句柄上限，多线程下载大文件不报错
ulimit -n 1048576 2>/dev/null || true

# 7. 网卡硬件大包发送/接收切片加速与硬件接收缓冲扩容 (TSO/GSO/GRO & RX/TX Ring Buffer & 禁用 EEE 节能断流)
command -v ethtool >/dev/null 2>&1 && {
    for dev in $(ls /sys/class/net 2>/dev/null); do
        case "$dev" in
            lo|veth*|br-*|docker*) continue ;;
        esac
        [ -w "/sys/class/net/$dev/device/power/control" ] && echo on >"/sys/class/net/$dev/device/power/control" 2>/dev/null || true
        ethtool --set-eee "$dev" eee off >/dev/null 2>&1 || true
        # 扩充网卡硬件环形缓冲区至 4096，大文件上传洪峰灌入 0 丢包
        ethtool -G "$dev" rx 4096 tx 4096 >/dev/null 2>&1 || ethtool -G "$dev" rx 2048 tx 2048 >/dev/null 2>&1 || true
        # 开启网卡硬件切片卸载与大包合并
        ethtool -K "$dev" rx on tx on tso on gso on gro on rx-udp-gro-forwarding on >/dev/null 2>&1 || true
        # 开启自适应中断合并，大文件高速上传时防止 CPU0 软中断跑满 100%
        ethtool -C "$dev" adaptive-rx on adaptive-tx on >/dev/null 2>&1 || true
    done
}

# 8. 将默认路由与局域网路由的 TCP 初始拥塞窗口/接收窗口 (initcwnd / initrwnd) 提升至 32 (46KB)，实现外网访问与大文件拉取 1-RTT 起步满速
ip -4 route show 2>/dev/null | while IFS= read -r rt; do
    [ -n "$rt" ] || continue
    case "$rt" in *"initcwnd"*) continue ;; esac
    ip -4 route change $rt initcwnd 32 initrwnd 32 >/dev/null 2>&1 || true
done

# 9. LuCI Web 后台 (uhttpd) 高并发调优与清理本地编译临时软件源
if uci -q get uhttpd.main >/dev/null 2>&1; then
    uci -q set uhttpd.main.max_requests='32'
    uci -q set uhttpd.main.max_connections='200'
    uci -q set uhttpd.main.http_keepalive='20'
    uci -q set uhttpd.main.network_timeout='60'
    uci -q set uhttpd.main.script_timeout='120'
    uci -q commit uhttpd
fi
sed -i '/helloworld/d;/video/d;/passwall/d;/mosdns/d;/openwrt_honk/d;/homeproxy/d;/lucky/d' /etc/apk/repositories.d/* /etc/apk/repositories /etc/opkg/distfeeds.conf 2>/dev/null || true

# 10. 注册每 5 分钟 Lucky 进程自愈守护与 OOM(-900)/Nice(-5) 续保（防止 Lucky 在线自更新重启后丢失免死保护）
mkdir -p /etc/crontabs
touch /etc/crontabs/root
if ! grep -q "lucky-watchdog" /etc/crontabs/root 2>/dev/null; then
    echo "*/5 * * * * [ -z \"\$(pidof lucky)\" ] && /etc/init.d/lucky start >/dev/null 2>&1; for p in lucky dnsmasq uhttpd; do for pid in \$(pidof \$p 2>/dev/null); do echo -900 >/proc/\$pid/oom_score_adj 2>/dev/null; renice -n -5 \$pid >/dev/null 2>&1; done; done # lucky-watchdog" >> /etc/crontabs/root
fi
/etc/init.d/cron enable >/dev/null 2>&1 || true
/etc/init.d/cron restart >/dev/null 2>&1 || true

sysctl -p /etc/sysctl.d/99-lucky-inbound.conf >/dev/null 2>&1 || true
exit 0
EOF
chmod +x files/etc/uci-defaults/99-lucky-appliance

echo "Basic settings applied."
verify_lucky_stack "${target_kernel_series}"

kernel_display="$(detect_kernel_version)"
default_ip_display="$(detect_default_ip)"
hostname_display="$(detect_hostname)"
theme_display="$(detect_theme)"
tuning_display="$(detect_performance_tuning)"
apps_display="$(detect_enabled_apps)"

echo ""
echo "======================================"
echo "ImmortalWrt ${kernel_display} Standalone LUCKY Appliance configuration complete"
echo "======================================"
echo "  - Kernel: ${kernel_display}"
echo "  - Default IP: ${default_ip_display}"
echo "  - Hostname: ${hostname_display}"
echo "  - Theme: ${theme_display}"
echo "  - Inbound & Proxy Tuning: ${tuning_display}"
echo "  - Dedicated Apps: ${apps_display}"
echo "======================================"
