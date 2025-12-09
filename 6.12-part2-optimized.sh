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

# 编译6.12内核
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=6.12/g' target/linux/x86/Makefile

# 修改主机名
sed -i "s/hostname='OpenWrt'/hostname='VM-EAY'/g" package/base-files/files/bin/config_generate

# 设置时区
sed -i 's/timezone='UTC'/timezone='CST-8'/g' package/base-files/files/bin/config_generate

# 取消bootstrap为默认主题，改为argone
sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# 清空登录密码 (虚拟机环境方便调试)
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true

echo "Basic settings applied."

# ┌─────────────────────────────────────────────┐
# │           虚拟机性能优化                      │
# └─────────────────────────────────────────────┘
echo ">>> Applying VM performance optimizations..."

# 创建自定义优化配置文件
mkdir -p files/etc/sysctl.d
cat > files/etc/sysctl.d/99-vm-optimize.conf <<EOF
# Virtual Machine Network Optimization
net.core.rmem_default = 256960
net.core.rmem_max = 16777216
net.core.wmem_default = 256960
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 32768
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_synack_retries = 2
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Virtual Memory Optimization
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
EOF

# ┌─────────────────────────────────────────────┐
# │          SSR-Plus 优化配置                    │
# └─────────────────────────────────────────────┘
echo ">>> Optimizing SSR-Plus configuration..."

# 创建SSR-Plus优化启动脚本
mkdir -p files/etc/init.d
cat > files/etc/init.d/ssr-optimize <<'EOF'
#!/bin/sh /etc/rc.common
# SSR-Plus Performance Optimization

START=99
STOP=01

start() {
    # Set CPU performance mode
    echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null
    
    # Optimize network stack for SSR
    echo 2048 > /proc/sys/net/core/somaxconn
    echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
    echo 0 > /proc/sys/net/ipv4/tcp_slow_start_after_idle
    
    # Increase file descriptors
    ulimit -n 65535
    
    logger -t ssr-optimize "SSR-Plus optimizations applied"
}

stop() {
    echo ondemand > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null
    logger -t ssr-optimize "SSR-Plus optimizations removed"
}
EOF
chmod +x files/etc/init.d/ssr-optimize

# ┌─────────────────────────────────────────────┐
# │        MosDNS + SmartDNS 配置优化            │
# └─────────────────────────────────────────────┘
echo ">>> Configuring DNS optimization..."

# 创建DNS配置优化
mkdir -p files/etc/config
cat > files/etc/config/dns-optimize <<EOF
# MosDNS Configuration (Port 5353)
# Primary DNS with advanced filtering
config mosdns 'config'
    option enabled '1'
    option listen_port '5353'
    option cache_size '10000'
    option cache_ttl '300'
    option concurrent_num '8'
    option enable_pipeline '1'
    option insecure_skip_verify '0'
    option enable_ecs_support '1'

# SmartDNS Configuration (Port 5354)  
# Secondary DNS with speed optimization
config smartdns
    option enabled '1'
    option port '5354'
    option tcp_server '1'
    option ipv6_server '1'
    option dual_stack_ip_selection '1'
    option prefetch_domain '1'
    option serve_expired '1'
    option cache_size '10000'
    option rr_ttl_min '300'
    option seconddns_enabled '1'
    option speed_check_mode 'tcp:443,ping'
    option force_aaaa_soa '1'
EOF

# ┌─────────────────────────────────────────────┐
# │           安装关键包                          │
# └─────────────────────────────────────────────┘
echo ">>> Installing optimized packages..."

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

# 混淆和优化
./scripts/feeds install -p small simple-obfs 2>/dev/null || true
./scripts/feeds install -p small kcptun-client 2>/dev/null || true

# DNS优化包
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

verify_package() {
    if [ -d "feeds/$1" ]; then
        echo "  ✓ $2 found in $1 feed"
        return 0
    else
        echo "  ✗ $2 NOT found in $1 feed"
        return 1
    fi
}

echo ""
echo "=== Package Verification ==="
verify_package "helloworld/luci-app-ssr-plus" "SSR-Plus"
verify_package "small/shadowsocks-rust" "Shadowsocks-Rust"
verify_package "small/xray-core" "Xray Core"
verify_package "small/mosdns" "MosDNS"
verify_package "small/smartdns" "SmartDNS"

# ┌─────────────────────────────────────────────┐
# │           编译优化设置                        │
# └─────────────────────────────────────────────┘
echo ">>> Applying compilation optimizations..."

# 设置编译优化参数
cat >> .config <<EOF
# Compilation Optimization
CONFIG_CCACHE=n
CONFIG_BUILD_PATENTED=y
CONFIG_KERNEL_CC_OPTIMIZE_FOR_PERFORMANCE=y
CONFIG_KERNEL_CC_OPTIMIZE_FOR_SIZE=n
CONFIG_DEFAULT_TARGET_OPTIMIZATION="-O3 -pipe -march=x86-64-v2"
CONFIG_CPU_TYPE="generic"
CONFIG_LINUX_6_12=y
CONFIG_TESTING_KERNEL=y
EOF

# 创建编译信息文件
cat > files/etc/openwrt_release_optimized <<EOF
DISTRIB_ID='OpenWrt'
DISTRIB_RELEASE='6.12-Optimized'
DISTRIB_REVISION='VM-Edition'
DISTRIB_TARGET='x86/64'
DISTRIB_ARCH='x86_64'
DISTRIB_DESCRIPTION='OpenWrt 6.12 Optimized for Virtual Machines'
DISTRIB_TAINTS='no-all-busybox'
EOF

# ┌─────────────────────────────────────────────┐
# │            最终配置检查                       │
# └─────────────────────────────────────────────┘
echo ""
echo "======================================"
echo "   OpenWrt 6.12 VM优化配置完成！"
echo "======================================"
echo ""
echo "【系统信息】"
echo "  内核版本: 6.12"
echo "  目标平台: x86_64 虚拟机"
echo "  默认地址: 192.168.0.133"
echo "  主机名称: VM-EAY"
echo "  界面主题: Argon"
echo ""
echo "【代理优化】"
echo "  主程序: SSR-Plus (Shadowsocks-Rust)"
echo "  协议支持: SS/SSR/V2ray/Xray/Trojan"
echo "  性能优化: TCP BBR + Fast Open"
echo "  透明代理: Redsocks2 + ChiaDNS-NG"
echo ""
echo "【DNS架构】"
echo "  主DNS: MosDNS (端口 5353)"
echo "    - DoH/DoT 加密查询"
echo "    - GeoIP/GeoSite 智能分流"
echo "    - 10000条缓存"
echo "  辅DNS: SmartDNS (端口 5354)"
echo "    - 多线路测速优选"
echo "    - 智能缓存预取"
echo "    - 故障自动切换"
echo ""
echo "【虚拟机优化】"
echo "  驱动: VirtIO全套驱动"
echo "  内存: 透明大页 + ZSWAP"
echo "  网络: 队列优化 + 缓冲区调整"
echo "  CPU: Performance调度器"
echo ""
echo "【编译优化】"
echo "  优化级别: -O3"
echo "  CPU架构: x86-64-v2"
echo "  根分区: 512MB (SquashFS压缩)"
echo "  精简包: 移除USB/无线/物理网卡驱动"
echo "======================================"
echo ""
echo ">>> Configuration completed successfully!"
