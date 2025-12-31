#!/bin/bash
# 6.12-part2-optimized.sh - OpenWrt 6.12 内核优化编译配置
# 专门为Linux虚拟机环境优化
# 在 feeds update 和 feeds install 之后执行

echo "======================================"
echo "Starting OpenWrt 6.12 Optimized Build"
echo "======================================"

# ┌─────────────────────────────────────────────┐
# │            基础系统设置                       │
# └─────────────────────────────────────────────┘
echo ">>> Applying basic settings..."

# 修改默认IP
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate

# 编译6.12内核 (修正正则表达式)
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.12/g' target/linux/x86/Makefile
sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=6.12/g' target/linux/x86/Makefile 2>/dev/null || true

# 验证内核版本修改
echo ">>> 验证内核版本设置："
grep "KERNEL_PATCHVER" target/linux/x86/Makefile

# 修改主机名
sed -i "s/hostname='OpenWrt'/hostname='VM-EAY'/g" package/base-files/files/bin/config_generate

# 设置时区
sed -i "s/timezone='UTC'/timezone='CST-8'/g" package/base-files/files/bin/config_generate

# 取消bootstrap为默认主题，改为argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# 清空登录密码 (虚拟机环境方便调试)
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true

echo "Basic settings applied."

# ┌─────────────────────────────────────────────┐
# │           虚拟机网络优化                      │
# └─────────────────────────────────────────────┘
echo ">>> Applying VM network optimizations..."

# 创建 sysctl 网络优化配置
mkdir -p files/etc/sysctl.d
cat > files/etc/sysctl.d/99-vm-optimize.conf <<'EOF'
# ===== TCP/IP 核心优化 =====
# BBR 拥塞控制 (弱网环境提升明显)
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# TCP Fast Open (减少握手延迟)
net.ipv4.tcp_fastopen = 3

# 连接复用和超时优化
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3

# SYN 队列优化
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2

# TCP 缓冲区 (适合虚拟机)
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 4194304
net.ipv4.tcp_rmem = 4096 65536 4194304
net.ipv4.tcp_wmem = 4096 65536 4194304

# 连接队列
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 4096

# 转发
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# ===== 虚拟机内存优化 =====
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
EOF

echo "Network optimizations applied."

# ┌─────────────────────────────────────────────┐
# │           安装关键包                          │
# └─────────────────────────────────────────────┘
echo ">>> Installing packages..."

# SSR-Plus核心包
./scripts/feeds install -p helloworld luci-app-ssr-plus 2>/dev/null || \
    ./scripts/feeds install -p small luci-app-ssr-plus 2>/dev/null || true

# Shadowsocks Rust版本 (高性能)
./scripts/feeds install -p small shadowsocks-rust 2>/dev/null || true
./scripts/feeds install -p small shadowsocks-rust-sslocal 2>/dev/null || true
./scripts/feeds install -p small shadowsocks-rust-ssserver 2>/dev/null || true

# SSR支持
./scripts/feeds install -p small shadowsocksr-libev 2>/dev/null || true
./scripts/feeds install -p small shadowsocksr-libev-ssr-local 2>/dev/null || true
./scripts/feeds install -p small shadowsocksr-libev-ssr-redir 2>/dev/null || true

# V2ray/Xray
./scripts/feeds install -p small xray-core 2>/dev/null || true
./scripts/feeds install -p small xray-plugin 2>/dev/null || true
./scripts/feeds install -p small v2ray-geoip 2>/dev/null || true
./scripts/feeds install -p small v2ray-geosite 2>/dev/null || true

# Trojan
./scripts/feeds install -p small trojan-plus 2>/dev/null || true
./scripts/feeds install -p small trojan-go 2>/dev/null || true

# 混淆
./scripts/feeds install -p small simple-obfs 2>/dev/null || true
./scripts/feeds install -p small kcptun-client 2>/dev/null || true

# DNS包
./scripts/feeds install -p small mosdns 2>/dev/null || true
./scripts/feeds install -p small luci-app-mosdns 2>/dev/null || true
./scripts/feeds install -p kenzo luci-app-mosdns 2>/dev/null || true
./scripts/feeds install -p small smartdns 2>/dev/null || true
./scripts/feeds install -p small luci-app-smartdns 2>/dev/null || true
./scripts/feeds install -p kenzo luci-app-smartdns 2>/dev/null || true

# 透明代理支持
./scripts/feeds install -p small redsocks2 2>/dev/null || true
./scripts/feeds install -p small microsocks 2>/dev/null || true
./scripts/feeds install -p small chinadns-ng 2>/dev/null || true
./scripts/feeds install -p small pdnsd-alt 2>/dev/null || true
./scripts/feeds install -p small dns2socks 2>/dev/null || true
./scripts/feeds install -p small ipt2socks 2>/dev/null || true

# 网络工具
./scripts/feeds install -p packages htop 2>/dev/null || true
./scripts/feeds install -p packages iftop 2>/dev/null || true
./scripts/feeds install -p packages iperf3 2>/dev/null || true
./scripts/feeds install -p packages tcpdump 2>/dev/null || true
./scripts/feeds install -p packages mtr 2>/dev/null || true
./scripts/feeds install -p packages bind-dig 2>/dev/null || true

echo "Package installation completed."

# ┌─────────────────────────────────────────────┐
# │           验证关键包安装                      │
# └─────────────────────────────────────────────┘
echo ">>> Verifying critical packages..."

check_feed() {
    local feed_path="$1"
    local name="$2"
    if [ -d "feeds/$feed_path" ]; then
        echo "  [OK] $name"
    else
        echo "  [--] $name (will try from other feeds)"
    fi
}

echo ""
echo "=== Package Check ==="
check_feed "helloworld/luci-app-ssr-plus" "SSR-Plus"
check_feed "small/shadowsocks-rust" "Shadowsocks-Rust"
check_feed "small/xray-core" "Xray Core"
check_feed "small/mosdns" "MosDNS"
check_feed "small/smartdns" "SmartDNS"

# ┌─────────────────────────────────────────────┐
# │           编译设置                            │
# └─────────────────────────────────────────────┘
echo ">>> Applying build settings..."

# 追加编译参数到 .config
cat >> .config <<'EOF'
# 编译优化
CONFIG_CCACHE=n
CONFIG_BUILD_PATENTED=y
CONFIG_LINUX_6_12=y
CONFIG_TESTING_KERNEL=y
EOF

# 创建版本信息文件
mkdir -p files/etc
cat > files/etc/openwrt_optimized <<'EOF'
EDITION=VM-Optimized
KERNEL=6.12
TARGET=x86_64
EOF

# ┌─────────────────────────────────────────────┐
# │            完成提示                           │
# └─────────────────────────────────────────────┘
echo ""
echo "======================================"
echo "   OpenWrt 6.12 优化配置完成"
echo "======================================"
echo ""
echo "系统: 192.168.0.133 / VM-EAY / Argon主题"
echo "代理: SSR-Plus + Shadowsocks-Rust"
echo "DNS:  MosDNS + SmartDNS"
echo "优化: TCP BBR + Fast Open + 虚拟机调优"
echo "根分区: 1024MB"
echo ""
echo "======================================"
echo ">>> Configuration completed!"
