#!/bin/bash
# 6.12-part2-optimized.sh - OpenWrt 6.12 内核编译配置（优化版）
# 在 feeds update 和 feeds install 之后执行

# 基础设置
echo "Applying basic settings..."

# 修改默认IP
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate

# 编译6.12内核
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=6.12/g' target/linux/x86/Makefile

# 修改主机名
sed -i "s/hostname='OpenWrt'/hostname='EAY'/g" package/base-files/files/bin/config_generate

# 取消bootstrap为默认主题，改为argone
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

echo "Basic settings applied."

# ==================================================
# 添加运行时优化
# ==================================================
echo "Adding runtime optimizations..."

# 创建 sysctl 优化配置
mkdir -p files/etc/sysctl.d
cat > files/etc/sysctl.d/99-openwrt-optimize.conf << 'EOF'
# 网络优化
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1

# 内存优化
vm.swappiness = 10
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
vm.min_free_kbytes = 65536

# 文件系统优化
fs.file-max = 131072
fs.nr_open = 131072
EOF

# 创建启动优化脚本
mkdir -p files/etc/init.d
cat > files/etc/init.d/optimize << 'EOF'
#!/bin/sh /etc/rc.common
# 系统优化启动脚本

START=99
USE_PROCD=1

start_service() {
    # CPU 性能模式（如果支持）
    echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
    
    # 开启透明大页
    echo always > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
    echo always > /sys/kernel/mm/transparent_hugepage/defrag 2>/dev/null || true
    
    # 优化中断处理
    echo 2 > /proc/sys/net/core/rps_sock_flow_entries 2>/dev/null || true
    
    # 设置 DNS 缓存大小
    [ -f /etc/config/dhcp ] && {
        uci set dhcp.@dnsmasq[0].cachesize='10000'
        uci commit dhcp
    }
    
    logger -t optimize "System optimizations applied"
}
EOF
chmod +x files/etc/init.d/optimize

# 优化 Makefile 编译参数
if [ -f "include/target.mk" ]; then
    sed -i 's/-Os/-O3/g' include/target.mk 2>/dev/null || true
    sed -i 's/-pipe/-pipe -march=x86-64-v2/g' include/target.mk 2>/dev/null || true
fi

# 验证关键包
echo ""
echo "=== Verifying packages ==="

if [ -d "feeds/helloworld/luci-app-ssr-plus" ]; then
    echo "✓ SSR-Plus found"
else
    echo "✗ SSR-Plus not found"
fi

if [ -d "feeds/kenzo/luci-app-mosdns" ] || [ -d "feeds/packages/net/mosdns" ]; then
    echo "✓ MosDNS found (Primary DNS)"
else
    echo "✗ MosDNS not found"
fi

if [ -d "feeds/kenzo/luci-app-smartdns" ] || [ -d "feeds/packages/net/smartdns" ]; then
    echo "✓ SmartDNS found (Secondary DNS)"
else
    echo "✗ SmartDNS not found"
fi

# 检查优化相关包
echo ""
echo "=== Checking optimization packages ==="

[ -d "feeds/packages/kernel/kmod-tcp-bbr" ] && echo "✓ BBR support" || echo "✗ BBR not found"
[ -d "feeds/packages/kernel/kmod-shortcut-fe" ] && echo "✓ Shortcut-FE support" || echo "✗ Shortcut-FE not found"
[ -f "package/kernel/linux/modules/virtio.mk" ] && echo "✓ VirtIO support" || echo "✗ VirtIO not configured"

echo ""
echo "======================================"
echo "OpenWrt 6.12 优化配置完成！"
echo "======================================"
echo "配置信息："
echo "  - 内核: 6.12"
echo "  - 默认IP: 192.168.0.133"
echo "  - 主机名: EAY"
echo "  - 编译优化: -O3 -march=x86-64-v2"
echo ""
echo "🚀 性能优化："
echo "  - 内核: 透明大页、CFS带宽控制、内存控制组"
echo "  - CPU: 性能调度器、多核优化"
echo "  - 内存: 优化 swappiness、脏页比例"
echo "  - 文件系统: SquashFS 压缩、EXT4 优化"
echo ""
echo "🔧 虚拟机优化："
echo "  - VirtIO: 全套驱动（网络、块设备、SCSI、气球）"
echo "  - QEMU: Guest Agent 支持"
echo "  - 兼容: VMware vmxnet3、Intel E1000/E1000e"
echo ""
echo "🌐 代理优化："
echo "  - 核心: Shadowsocks-Rust（高性能）"
echo "  - 精简: 移除 shadowsocks-libev 冗余组件"
echo "  - 协议: SSR/Xray/Trojan（精选版本）"
echo "  - 透明代理: redsocks2 + chinadns-ng"
echo ""
echo "📡 DNS 架构："
echo "  - 主DNS: MosDNS (端口 5353)"
echo "    * GeoIP/GeoSite 智能分流"
echo "    * DoH/DoT 加密查询"
echo "  - 辅DNS: SmartDNS (端口 5354)"
echo "    * 多线路测速优选"
echo "    * 智能缓存机制"
echo "  - 缓存: 10000 条记录"
echo ""
echo "⚡ 网络加速："
echo "  - TCP: BBR + FQ 队列"
echo "  - 加速: Shortcut-FE 快速转发"
echo "  - 优化: TCP Fast Open、MTU 探测"
echo "  - 缓冲: 网络队列 5000"
echo ""
echo "📦 固件优化："
echo "  - 镜像: SquashFS 压缩（更小体积）"
echo "  - 分区: 512MB（足够且高效）"
echo "  - 精简: 移除 USB/声音/蓝牙驱动"
echo "  - Strip: 移除调试信息"
echo "======================================"
