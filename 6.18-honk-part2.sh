#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/common-proxy-verification.sh"

target_kernel_series="6.18"
target_default_ip="192.168.0.233"
target_hostname="EAY-HONK"

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

    ip="$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' package/base-files/files/bin/config_generate 2>/dev/null | grep -v '^127\.' | head -n 1 || true)"
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

detect_performance_defaults() {
    local items=()

    if [ -f files/etc/init.d/performance-mode ]; then
        items+=("governor/EPP performance")
    fi

    if config_is_enabled CONFIG_PACKAGE_irqbalance; then
        items+=("irqbalance")
    fi

    if [ -f files/etc/uci-defaults/99-system-performance ] && grep -q "packet_steering='1'" files/etc/uci-defaults/99-system-performance; then
        items+=("packet steering")
    fi

    if [ -f files/etc/init.d/performance-mode ] && grep -q 'rps_cpus' files/etc/init.d/performance-mode && grep -q 'xps_cpus' files/etc/init.d/performance-mode; then
        items+=("RPS/XPS")
    fi

    if [ -f files/etc/init.d/performance-mode ] && grep -q 'rx-udp-gro-forwarding' files/etc/init.d/performance-mode; then
        items+=("UDP GRO")
    fi

    if config_is_enabled CONFIG_PACKAGE_kmod-virtio-rng; then
        items+=("Virtio-RNG")
    fi

    if config_is_enabled CONFIG_PACKAGE_kmod-tcp-bbr || { [ -f files/etc/init.d/performance-mode ] && grep -q 'tcp_congestion_control=bbr' files/etc/init.d/performance-mode; }; then
        items+=("BBR")
    fi

    if config_is_enabled CONFIG_KERNEL_DEBUG_INFO_BTF; then
        items+=("Kernel BTF")
    fi

    items+=("SmartDNS-6053 Direct Link")
    items+=("dae0/dae0peer Queue Tuning")

    join_by_comma "${items[@]}"
}

detect_proxy_stack() {
    if config_is_enabled CONFIG_PACKAGE_honk && config_is_enabled CONFIG_PACKAGE_luci-app-honk; then
        echo "HONK (eBPF TC-bpf Engine) + Doona Web UI + SmartDNS 6053"
    else
        echo "not detected"
    fi
}

detect_enabled_apps() {
    local apps=()

    config_is_enabled CONFIG_PACKAGE_honk && apps+=("Honk")
    config_is_enabled CONFIG_PACKAGE_luci-app-honk && apps+=("luci-app-honk")
    config_is_enabled CONFIG_PACKAGE_smartdns && apps+=("SmartDNS")
    config_is_enabled CONFIG_PACKAGE_luci-app-turboacc && apps+=("Turbo ACC")

    join_by_comma "${apps[@]}"
}

echo "Applying basic settings for 6.18 HONK..."

sed -i "s/192\\.168\\.1\\.1/${target_default_ip}/g" package/base-files/files/bin/config_generate
sed -i "s/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=${target_kernel_series}/g" target/linux/x86/Makefile

# Clear default root password (ImmortalWrt default-settings path)
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

# ==============================================================================
# HONK (eBPF) 专属独立调优（仅在 HONK 编译工作区生效，绝不影响其他固件版本）
# ==============================================================================
echo "Applying HONK + SmartDNS dedicated optimizations..."

# 1. 修正 files/etc/uci-defaults/99-system-performance 中的 HomeProxy 遗留设定：
#    - 将 Dnsmasq 上游从已移除的 Sing-box (127.0.0.1#5333) 改为本地 SmartDNS (127.0.0.1#6053)，保障刷机即刻高速解析上网
#    - 关闭 Firewall4 的 flow_offloading='0'，避免与 Honk 的 TC eBPF 直通转发和 nfqueue 首包 DPI 嗅探冲突
#    - 为 Honk 的 dae0 / dae0peer 虚拟以太网对扩充 txqueuelen 4096
if [ -f "files/etc/uci-defaults/99-system-performance" ]; then
    sed -i "s/127\.0\.0\.1#5333/127.0.0.1#6053/g" files/etc/uci-defaults/99-system-performance
    sed -i "s/flow_offloading='1'/flow_offloading='0'/g" files/etc/uci-defaults/99-system-performance
    sed -i "s/uci -q del dhcp.@dnsmasq\[0\].noresolv.*/uci -q set dhcp.@dnsmasq[0].noresolv='1'/g" files/etc/uci-defaults/99-system-performance
    sed -i 's|/sys/class/net/singtun\*|/sys/class/net/singtun* /sys/class/net/dae*|g' files/etc/uci-defaults/99-system-performance
fi

# 2. 在 files/etc/init.d/performance-mode 中为 Honk 的 dae0 / dae0peer 虚拟网卡开启 4096 队列扩容
if [ -f "files/etc/init.d/performance-mode" ]; then
    sed -i 's/tun\*|singtun\*)/tun*|singtun*|dae*)/g' files/etc/init.d/performance-mode
fi

# 3. 预置 Honk eBPF 必需的 5 大内核模块开机自动加载与 bpffs 挂载保障，确保 control.sh 预检 100% 通过
mkdir -p files/etc/modules.d files/etc/uci-defaults
cat << 'EOF' > files/etc/modules.d/60-honk-ebpf
sch_ingress
cls_bpf
veth
nft_queue
nfnetlink_queue
EOF

cat << 'EOF' > files/etc/uci-defaults/98-honk-ebpf-init
#!/bin/sh
# 确保 bpffs 挂载与 Honk 所需内核模块就绪
if [ -d /sys/fs/bpf ] && ! grep -q ' /sys/fs/bpf bpf ' /proc/mounts 2>/dev/null; then
	mount -t bpf bpf /sys/fs/bpf 2>/dev/null || true
fi

for mod in sch_ingress cls_bpf veth nft_queue nfnetlink_queue; do
	modprobe "$mod" 2>/dev/null || true
done

exit 0
EOF
chmod +x files/etc/uci-defaults/98-honk-ebpf-init

# 4. 深度优化 Honk 与 SmartDNS 黄金搭配模板：
#    - 国内 DNS (smartdns) 直接对接本地 SmartDNS (udp://127.0.0.1:6053)，享受 26万条内存缓存与国内大厂并发测速
#    - 海外 DNS (googledoh / cfdoh) 采用纯 IP 免死锁 Google & Cloudflare DoH 走代理防污染（双公网 DoH 互备）
#    - 屏蔽 HTTPS/SVCB (qtype https) 防止浏览器 ECH 绕过分流
#    - 局域网私有域名 (geosite: private) 放行回退 (asis) 给 Dnsmasq 解析
#    - DNS 响应阶段 (response) 拦截海外域名返回私有 IP 的投毒特征
#    - 顶层直连放行 dnsmasq 与 smartdns 进程流量 (pname -> direct(must))，彻底杜绝 DNS 回环死锁
#    - 在 eBPF 内核态精准阻断非国内的海外 QUIC (UDP 443)，既让 YouTube/Google 秒切稳定 TCP，又保留国内抖音/B站 QUIC 加速
#    - fallback: proxy 确保非国内海外流量 100% 正常走节点代理
apply_honk_dae_config() {
    local dae_content='include {
    system.dae
}

group {
    proxy {
        policy: min_moving_avg
    }
}

dns {
    upstream {
        # 对接本机 SmartDNS (6053端口)：承接国内域名并发测速与 26万条内存极速缓存
        smartdns: '\''udp://127.0.0.1:6053'\'' -> direct
        # 海外 DoH 双节点冗余：纯 IP + SNI 模式通过代理隧道解析，物理隔绝 GFW 抢答投毒
        googledoh: '\''https://8.8.8.8/dns-query?tls_server_name=dns.google'\'' -> proxy
        cfdoh: '\''https://1.1.1.1/dns-query?tls_server_name=cloudflare-dns.com'\'' -> proxy
    }
    routing {
        request {
            # 拦截 HTTPS/SVCB (Type 65) 查询，防止现代浏览器启用 ECH 绕过 SNI 分流规则
            qtype(https) -> reject
            # 局域网私有域名 (如 *.lan、路由器主机名) 放行给 Dnsmasq 进行本地解析
            qname(geosite: private) -> asis
            # 国内域名交由 SmartDNS 进行国内多大厂并发测速，返回最优 CDN 节点 IP
            qname(geosite: cn) -> smartdns
            # 海外与未命中域名优先通过 Google DoH 解析，回退 Cloudflare DoH
            fallback: googledoh
        }
        response {
            upstream(smartdns) -> accept
            # 阻断海外域名解析出私有保留 IP (投毒特征防护)
            !qname(geosite: cn) && ip(geoip: private) && !qname(geosite: private) -> reject
            fallback: accept
        }
    }
}

routing {
    # 1. 强制放行本机 Dnsmasq 与 SmartDNS 自身发出的上游解析流量，彻底杜绝 eBPF 拦截回环死锁
    pname(dnsmasq, smartdns) -> direct(must)
    # 2. 组播与局域网广播直连
    dip(224.0.0.0/3, '\''ff00::/8'\'') -> direct
    # 3. 路由器自身管理面板与私有局域网直连
    # honk:local-direct-begin
    # honk:local-direct-end
    dip(geoip: private) && !dport(53) -> direct(must)
    # 4. 国内 IP 与国内域名直连放行
    dip(geoip: cn) && !dport(53) -> direct(must)
    domain(geosite: cn) -> direct
    # 5. 在 eBPF 内核态精准阻断海外 QUIC (UDP 443)，迫使客户端浏览器秒切极速稳定的 TCP (TLS 1.3)
    l4proto(udp) && dport(443) -> block
    # 6. 其余所有海外流量自动走代理节点
    fallback: proxy
}'

    # 预置到固件 rootfs files/etc/honk/config.dae
    mkdir -p files/etc/honk
    printf '%s\n' "$dae_content" > files/etc/honk/config.dae
    echo "Pre-seeded files/etc/honk/config.dae."

    # 注入到源码树中的所有可能路径
    for dae_path in package/openwrt-honk/honk/files/config.dae package/openwrt-honk/files/config.dae package/honk/files/config.dae; do
        if [ -d "${dae_path%/*}" ]; then
            printf '%s\n' "$dae_content" > "$dae_path"
            echo "Injected optimized config.dae into ${dae_path}"
        fi
    done
}
apply_honk_dae_config

echo "Basic settings and HONK dedicated optimizations applied."
verify_honk_stack "${target_kernel_series}"

kernel_display="$(detect_kernel_version)"
default_ip_display="$(detect_default_ip)"
hostname_display="$(detect_hostname)"
theme_display="$(detect_theme)"
performance_display="$(detect_performance_defaults)"
proxy_stack_display="$(detect_proxy_stack)"
apps_display="$(detect_enabled_apps)"

echo ""
echo "======================================"
echo "ImmortalWrt ${kernel_display} HONK (eBPF) configuration complete"
echo "======================================"
echo "  - Kernel: ${kernel_display}"
echo "  - Default IP: ${default_ip_display}"
echo "  - Hostname: ${hostname_display}"
echo "  - Theme: ${theme_display}"
echo "  - Performance defaults: ${performance_display}"
echo "  - Proxy stack: ${proxy_stack_display}"
echo "  - Apps: ${apps_display}"
echo "======================================"
