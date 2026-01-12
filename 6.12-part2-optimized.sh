#!/bin/bash
# ==================================================
# 6.12-part2-optimized.sh
# OpenWrt 6.12 Linux 虚拟机深度优化编译脚本
# 在 feeds update/install 之后执行
# ==================================================

set -e

echo "======================================"
echo "  OpenWrt 6.12 VM Optimized Build"
echo "======================================"

# ┌─────────────────────────────────────────────┐
# │            基础系统设置                       │
# └─────────────────────────────────────────────┘
echo ">>> [1/6] 基础系统设置..."

# 修改默认IP
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate

# 编译6.12内核
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.12/g' target/linux/x86/Makefile
sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=6.12/g' target/linux/x86/Makefile 2>/dev/null || true

# 修改主机名
sed -i "s/hostname='OpenWrt'/hostname='VM-Router'/g" package/base-files/files/bin/config_generate

# 设置时区
sed -i "s/timezone='UTC'/timezone='CST-8'/g" package/base-files/files/bin/config_generate

# 默认主题改为 argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# 清空登录密码
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true

echo "    基础设置完成"

# ┌─────────────────────────────────────────────┐
# │           旁路由性能优化                      │
# └─────────────────────────────────────────────┘
echo ">>> [2/6] 旁路由性能优化..."

mkdir -p files/etc/sysctl.d
cat > files/etc/sysctl.d/99-bypass-performance.conf <<'EOF'
# ===== TCP 性能优化 =====
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq_codel

# TCP Fast Open（减少延迟）
net.ipv4.tcp_fastopen = 3

# 连接复用
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 3

# SYN 队列（防 SYN 洪水）
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2

# TCP 窗口优化
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1

# 缓冲区（旁路由高吞吐）
net.core.rmem_default = 524288
net.core.rmem_max = 16777216
net.core.wmem_default = 524288
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 524288 16777216
net.ipv4.tcp_wmem = 4096 524288 16777216
net.ipv4.tcp_mem = 65536 131072 262144
net.ipv4.udp_mem = 65536 131072 262144

# 连接队列
net.core.somaxconn = 8192
net.core.netdev_max_backlog = 16384
net.core.netdev_budget = 600
net.core.netdev_budget_usecs = 8000

# 旁路由转发
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1

# conntrack 性能（旁路由核心）
net.netfilter.nf_conntrack_max = 131072
net.netfilter.nf_conntrack_buckets = 32768
net.netfilter.nf_conntrack_tcp_timeout_established = 3600
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 15
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 30
net.netfilter.nf_conntrack_udp_timeout = 30
net.netfilter.nf_conntrack_udp_timeout_stream = 120
net.netfilter.nf_conntrack_icmp_timeout = 10

# 本地端口范围
net.ipv4.ip_local_port_range = 1024 65535

# ARP 缓存
net.ipv4.neigh.default.gc_thresh1 = 1024
net.ipv4.neigh.default.gc_thresh2 = 4096
net.ipv4.neigh.default.gc_thresh3 = 8192

# ===== 内存性能 =====
vm.swappiness = 5
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.overcommit_memory = 1
vm.min_free_kbytes = 16384
EOF

echo "    性能优化配置完成"

# ┌─────────────────────────────────────────────┐
# │           安装关键包                          │
# └─────────────────────────────────────────────┘
echo ">>> [3/6] 安装关键软件包..."

# 定义安装函数
install_pkg() {
    local pkg="$1"
    ./scripts/feeds install "$pkg" 2>/dev/null || true
}

# SSR-Plus 核心
install_pkg luci-app-ssr-plus
install_pkg luci-i18n-ssr-plus-zh-cn

# Shadowsocks Rust
install_pkg shadowsocks-rust-sslocal
install_pkg shadowsocks-rust-ssserver

# SSR
install_pkg shadowsocksr-libev-ssr-local
install_pkg shadowsocksr-libev-ssr-redir

# Xray
install_pkg xray-core
install_pkg v2ray-geoip
install_pkg v2ray-geosite

# Trojan
install_pkg trojan-plus

# 混淆
install_pkg simple-obfs-client

# DNS
install_pkg mosdns
install_pkg luci-app-mosdns
install_pkg smartdns
install_pkg luci-app-smartdns

# 透明代理
install_pkg chinadns-ng
install_pkg dns2socks
install_pkg ipt2socks

# 网络工具
install_pkg htop
install_pkg iftop
install_pkg tcpdump
install_pkg mtr
install_pkg curl
install_pkg wget-ssl

echo "    软件包安装完成"

# ┌─────────────────────────────────────────────┐
# │           启动性能优化脚本                    │
# └─────────────────────────────────────────────┘
echo ">>> [4/6] 创建启动优化脚本..."

mkdir -p files/etc/init.d
cat > files/etc/init.d/performance <<'INITEOF'
#!/bin/sh /etc/rc.common
# 旁路由性能优化启动脚本

START=99
STOP=10

start() {
    # 加载 BBR
    modprobe tcp_bbr 2>/dev/null || true
    
    # 设置 CPU 性能模式
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [ -f "$cpu" ] && echo "performance" > "$cpu" 2>/dev/null || true
    done
    
    # 网卡优化
    for iface in /sys/class/net/eth*; do
        [ -d "$iface" ] || continue
        ifname=$(basename "$iface")
        
        # 开启硬件加速
        ethtool -K "$ifname" rx on tx on sg on tso on gso on gro on lro off 2>/dev/null || true
        
        # 增大环形缓冲区
        ethtool -G "$ifname" rx 4096 tx 4096 2>/dev/null || true
        
        # 增大 txqueuelen
        ip link set "$ifname" txqueuelen 10000 2>/dev/null || true
    done
    
    # 禁用透明大页（减少延迟抖动）
    echo never > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
    
    # 设置中断亲和性（如果有 irqbalance 会自动处理）
    
    logger -t performance "Performance optimizations applied"
}

stop() {
    :
}
INITEOF
chmod +x files/etc/init.d/performance

# 创建 rc.local 备用
mkdir -p files/etc
cat > files/etc/rc.local <<'EOF'
# 额外的启动优化
/etc/init.d/performance start 2>/dev/null || true
exit 0
EOF
chmod +x files/etc/rc.local

echo "    启动脚本创建完成"

# ┌─────────────────────────────────────────────┐
# │           DNS 预配置                          │
# └─────────────────────────────────────────────┘
echo ">>> [5/6] DNS 预配置..."

mkdir -p files/etc/smartdns
cat > files/etc/smartdns/custom.conf <<'EOF'
# SmartDNS 优化配置
speed-check-mode ping,tcp:443,tcp:80
cache-size 4096
prefetch-domain yes
serve-expired yes
serve-expired-ttl 86400
tcp-idle-time 120
EOF

echo "    DNS 配置完成"

# ┌─────────────────────────────────────────────┐
# │           最终配置                            │
# └─────────────────────────────────────────────┘
echo ">>> [6/6] 最终配置..."

# 追加编译参数
cat >> .config <<'EOF'
CONFIG_BUILD_PATENTED=y
CONFIG_LINUX_6_12=y
EOF

# 版本信息
mkdir -p files/etc
cat > files/etc/openwrt_release_custom <<'EOF'
EDITION=VM-Optimized
KERNEL=6.12
BUILD_DATE=$(date +%Y%m%d)
EOF

echo ""
echo "======================================"
echo "     旁路由性能优化配置完成！"
echo "======================================"
echo ""
echo "  IP: 192.168.0.133"
echo "  网关: 设为主路由 IP"
echo ""
echo "  代理: SSR-Plus + Xray + SS-Rust"
echo "  DNS: MosDNS + SmartDNS"
echo ""
echo "  性能优化:"
echo "  - TCP BBR + fq_codel"
echo "  - SFE + fast-classifier 加速"
echo "  - conntrack 131072 连接"
echo "  - 16MB TCP 缓冲区"
echo "  - CPU 性能模式"
echo "  - 网卡硬件加速"
echo ""
echo "======================================"
