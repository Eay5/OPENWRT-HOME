#!/bin/bash
set -euo pipefail

install_from_feed() {
    local feed="$1"
    shift
    local pkg

    for pkg in "$@"; do
        echo "Installing ${pkg} from ${feed}..."
        ./scripts/feeds install -p "${feed}" "${pkg}"
    done
}

force_config() {
    local symbol="$1"
    local value="$2"

    touch .config
    sed -i "/^${symbol}=.*/d" .config
    sed -i "/^# ${symbol} is not set$/d" .config
    echo "${symbol}=${value}" >> .config
}

echo "======================================"
echo "  OpenWrt 6.12 VM Optimized Build"
echo "======================================"

echo "Applying base settings..."
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.12/g' target/linux/x86/Makefile
sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=6.12/g' target/linux/x86/Makefile 2>/dev/null || true
sed -i "s/hostname='OpenWrt'/hostname='VM-Router'/g" package/base-files/files/bin/config_generate
sed -i "s/timezone='UTC'/timezone='CST-8'/g" package/base-files/files/bin/config_generate
sed -i "s/zonename='UTC'/zonename='Asia\\/Shanghai'/g" package/base-files/files/bin/config_generate 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true

echo "Writing performance tuning files..."
mkdir -p files/etc/sysctl.d
cat > files/etc/sysctl.d/99-bypass-performance.conf <<'EOF'
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq_codel
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.core.rmem_default = 524288
net.core.rmem_max = 16777216
net.core.wmem_default = 524288
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 524288 16777216
net.ipv4.tcp_wmem = 4096 524288 16777216
net.ipv4.tcp_mem = 65536 131072 262144
net.ipv4.udp_mem = 65536 131072 262144
net.core.somaxconn = 8192
net.core.netdev_max_backlog = 16384
net.core.netdev_budget = 600
net.core.netdev_budget_usecs = 8000
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
net.netfilter.nf_conntrack_max = 131072
net.netfilter.nf_conntrack_buckets = 32768
net.netfilter.nf_conntrack_tcp_timeout_established = 3600
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 15
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 30
net.netfilter.nf_conntrack_udp_timeout = 30
net.netfilter.nf_conntrack_udp_timeout_stream = 120
net.netfilter.nf_conntrack_icmp_timeout = 10
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.neigh.default.gc_thresh1 = 1024
net.ipv4.neigh.default.gc_thresh2 = 4096
net.ipv4.neigh.default.gc_thresh3 = 8192
vm.swappiness = 5
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.overcommit_memory = 1
vm.min_free_kbytes = 16384
EOF

mkdir -p files/etc/init.d
cat > files/etc/init.d/performance <<'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10

start() {
    modprobe tcp_bbr 2>/dev/null || true

    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [ -f "$cpu" ] && echo "performance" > "$cpu" 2>/dev/null || true
    done

    for iface in /sys/class/net/eth*; do
        [ -d "$iface" ] || continue
        ifname=$(basename "$iface")

        ethtool -K "$ifname" rx on tx on sg on tso on gso on gro on lro off 2>/dev/null || true
        ethtool -G "$ifname" rx 4096 tx 4096 2>/dev/null || true
        ip link set "$ifname" txqueuelen 10000 2>/dev/null || true
    done

    echo never > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
    logger -t performance "Performance optimizations applied"
}

stop() {
    :
}
EOF
chmod +x files/etc/init.d/performance

mkdir -p files/etc
cat > files/etc/rc.local <<'EOF'
/etc/init.d/performance start 2>/dev/null || true
exit 0
EOF
chmod +x files/etc/rc.local

mkdir -p files/etc/smartdns
cat > files/etc/smartdns/custom.conf <<'EOF'
speed-check-mode ping,tcp:443,tcp:80
cache-size 4096
prefetch-domain yes
serve-expired yes
serve-expired-ttl 86400
tcp-idle-time 120
EOF

echo "Installing pinned feed packages..."
install_from_feed small \
    luci-app-ssr-plus \
    shadowsocks-rust \
    shadowsocksr-libev \
    simple-obfs \
    xray-core \
    trojan-plus \
    v2ray-geoip \
    v2ray-geosite \
    mosdns \
    luci-app-mosdns \
    chinadns-ng \
    dns2socks \
    ipt2socks

install_from_feed kenzo \
    luci-app-smartdns \
    luci-theme-argon

install_from_feed packages smartdns

force_config CONFIG_BUILD_PATENTED y
force_config CONFIG_LINUX_6_12 y
force_config CONFIG_PACKAGE_autosamba n
force_config CONFIG_PACKAGE_miniupnpd n
force_config CONFIG_PACKAGE_luci-app-upnp n
force_config CONFIG_PACKAGE_luci-i18n-upnp-zh-cn n
force_config CONFIG_KERNEL_SWAP y

mkdir -p files/etc
cat > files/etc/openwrt_release_custom <<EOF
EDITION=VM-Optimized
KERNEL=6.12
BUILD_DATE=$(date +%Y%m%d)
EOF

echo
echo "======================================"
echo "Optimized 6.12 package setup completed."
echo "  IP    : 192.168.0.133"
echo "  Host  : VM-Router"
echo "  Stack : SSR-Plus + Xray + SS-Rust"
echo "  DNS   : MosDNS + SmartDNS"
echo "======================================"
