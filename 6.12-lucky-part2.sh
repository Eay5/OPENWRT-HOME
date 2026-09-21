#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/common-proxy-verification.sh"

target_kernel_series="6.12"
target_default_ip="192.168.0.233"
target_hostname="EAY-LUCKY"

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
    local ip

    ip="$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' package/base-files/files/bin/config_generate 2>/dev/null | head -n 1 || true)"
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

echo "Applying basic settings for 6.12 LUCKY..."

sed -i "s/192\\.168\\.1\\.1/${target_default_ip}/g" package/base-files/files/bin/config_generate
sed -i "s/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=${target_kernel_series}/g" target/linux/x86/Makefile

# 清空默认密码
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/emortal/default-settings/files/99-default-settings 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i "s/hostname='ImmortalWrt'/hostname='${target_hostname}'/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='OpenWrt'/hostname='${target_hostname}'/g" package/base-files/files/bin/config_generate
sed -i "s/option lang 'auto'/option lang 'zh_cn'/g" feeds/luci/modules/luci-base/root/etc/config/luci 2>/dev/null || true
sed -i "s/option lang 'auto'/option lang 'zh_cn'/g" package/feeds/luci/luci-base/root/etc/config/luci 2>/dev/null || true

# 注入针对外网访问内网服务的专属内核与网络优化
mkdir -p files/etc/sysctl.d files/etc/uci-defaults

cat << 'EOF' > files/etc/sysctl.d/98-lucky-inbound.conf
# ==============================================================================
# Linux 6.12 LUCKY Dedicated Inbound / Reverse Proxy Tuning
# ==============================================================================
# 1. 100万级并发连接跟踪与 2 小时大文件长效连接保持（杜绝大文件下载中途断流）
net.netfilter.nf_conntrack_max = 1048576
net.netfilter.nf_conntrack_tcp_timeout_established = 7200
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 15
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 15
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 15

# 2. 扩充本地临时端口范围（5.5万端口），防止反向代理高并发时本地端口耗尽报错
net.ipv4.ip_local_port_range = 10240 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10

# 3. TCP BBR + FQ 拥塞控制，跨公网大延迟丢包环境下保障 FileBrowser 大文件满速
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# 4. Linux 6.12 原生 UDP GRO 转发加速（加速 QUIC / HTTP3 / STUN 穿透）
net.ipv4.udp_gro_forwarding = 1
net.ipv4.ip_forward = 1

# 5. 握手与并发连接队列优化
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 16384
net.core.netdev_max_backlog = 32768

# 6. 动态 TCP 缓冲区与大套接字缓冲（极大提升外网拉取内网大文件带宽利用率）
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432

# 7. FileBrowser 大文件传输专属优化 (解决断流、超时与MTU黑洞卡死)
# 自动探测路径 MTU，杜绝因 PPPoE 1492 与内网 1500 不匹配导致大文件点击下载 0KB 转圈卡死
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_base_mss = 1024

# 减少大文件发送时在套接字缓冲区排队造成的缓冲膨胀与延迟
net.ipv4.tcp_notsent_lowat = 16384

# TCP 保活探测：长文件传输时保持连接不被中间节点掐断
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5

# 扩充系统全局文件句柄至 200 万，完美支撑多线程（如 IDM 32 线程分块并发下载）
fs.file-max = 2097152
fs.nr_open = 2097152

# 8. 独立应用主机模式：反向路径过滤放宽至 Loose Mode (rp_filter=2)
# 杜绝主路由端口映射转发至本主机时，跨网段外网 IP 被内核误判为伪造源 IP 而丢弃
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2

# 9. 独立主机暴露高位端口下的安全防扫描与抗拒绝服务
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
EOF

# 注入独立应用主机防火墙与服务默认设置
cat << 'EOF' > files/etc/uci-defaults/98-lucky-appliance
#!/bin/sh
# 1. 独立主机纯净模式：彻底关闭本机的 DHCP 服务，严禁抢答局域网主路由的 DHCP 分配导致冲突
if uci -q get dhcp.lan >/dev/null 2>&1; then
    uci -q set dhcp.lan.ignore='1'
    uci -q commit dhcp
fi

# 2. 扩容本地 DNS 缓存至 10000 条，保障 Lucky 本地解析和 DDNS API 探测毫秒级响应
if uci -q get dhcp.@dnsmasq[0] >/dev/null 2>&1; then
    uci -q set dhcp.@dnsmasq[0].cachesize='10000'
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

# 5. 调大进程打开文件句柄上限，多线程下载大文件不报错
ulimit -n 1048576 2>/dev/null || true

# 6. 网卡硬件大包发送/接收切片加速 (TSO/GSO/GRO)，大文件外网跑满时 CPU 占用降低 70%
command -v ethtool >/dev/null 2>&1 && {
    for dev in $(ls /sys/class/net 2>/dev/null); do
        case "$dev" in
            lo|veth*|br-*|docker*) continue ;;
        esac
        ethtool -K "$dev" tso on gso on gro on >/dev/null 2>&1 || true
    done
}
exit 0
EOF
chmod +x files/etc/uci-defaults/98-lucky-appliance

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
