#!/bin/bash
# 6.12-part2-optimized.sh - OpenWrt 6.12 内核编译配置
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

# 强制设置内核版本为 6.12（用户确认存在）
echo ">>> 强制设置内核版本为 6.12..."
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.12/g' target/linux/x86/Makefile

# 验证内核版本修改
echo ">>> 验证内核版本设置："
grep "KERNEL_PATCHVER" target/linux/x86/Makefile

# 修改主机名
sed -i "s/hostname='OpenWrt'/hostname='VM-EAY'/g" package/base-files/files/bin/config_generate

# 设置时区
sed -i "s/timezone='UTC'/timezone='CST-8'/g" package/base-files/files/bin/config_generate 2>/dev/null || true

# 取消bootstrap为默认主题，改为argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

echo "Basic settings applied."

# ┌─────────────────────────────────────────────┐
# │           强制移除 KSMBd                      │
# └─────────────────────────────────────────────┘
echo ">>> Forcefully removing KSMBd packages..."

rm -rf feeds/*/luci-app-ksmbd 2>/dev/null || true
rm -rf feeds/*/ksmbd-server 2>/dev/null || true
rm -rf feeds/*/ksmbd-utils 2>/dev/null || true
rm -rf feeds/*/ksmbd-tools 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-ksmbd 2>/dev/null || true
rm -rf feeds/packages/net/ksmbd-tools 2>/dev/null || true
rm -rf feeds/packages/kernel/kmod-fs-ksmbd 2>/dev/null || true
rm -rf package/feeds/*/luci-app-ksmbd 2>/dev/null || true
rm -rf package/feeds/*/ksmbd* 2>/dev/null || true

echo "KSMBd packages removed."

# ┌─────────────────────────────────────────────┐
# │           验证关键包                          │
# └─────────────────────────────────────────────┘
echo ""
echo "=== Verifying packages ==="

if [ -d "feeds/helloworld/luci-app-ssr-plus" ]; then
    echo "✓ SSR-Plus found in helloworld"
elif [ -d "feeds/small/luci-app-ssr-plus" ]; then
    echo "✓ SSR-Plus found in small"
else
    echo "✗ SSR-Plus not found"
fi

if [ -d "feeds/small/mosdns" ] || [ -d "feeds/packages/net/mosdns" ]; then
    echo "✓ MosDNS found"
else
    echo "✗ MosDNS not found"
fi

if [ -d "feeds/small/smartdns" ] || [ -d "feeds/packages/net/smartdns" ]; then
    echo "✓ SmartDNS found"
else
    echo "✗ SmartDNS not found"
fi

# ┌─────────────────────────────────────────────┐
# │           安装关键包                          │
# └─────────────────────────────────────────────┘
echo ""
echo "=== Installing packages ==="

# SSR-Plus 及依赖
./scripts/feeds install -p helloworld luci-app-ssr-plus 2>/dev/null || \
    ./scripts/feeds install -p small luci-app-ssr-plus 2>/dev/null || true
./scripts/feeds install -p helloworld shadowsocks-libev 2>/dev/null || \
    ./scripts/feeds install -p small shadowsocks-libev 2>/dev/null || true
./scripts/feeds install -p helloworld shadowsocks-libev-ss-server 2>/dev/null || \
    ./scripts/feeds install -p small shadowsocks-libev-ss-server 2>/dev/null || true
./scripts/feeds install -p helloworld shadowsocks-libev-ss-redir 2>/dev/null || \
    ./scripts/feeds install -p small shadowsocks-libev-ss-redir 2>/dev/null || true
./scripts/feeds install -p helloworld shadowsocks-libev-ss-local 2>/dev/null || \
    ./scripts/feeds install -p small shadowsocks-libev-ss-local 2>/dev/null || true
./scripts/feeds install -p small shadowsocks-rust 2>/dev/null || true
./scripts/feeds install -p small shadowsocksr-libev 2>/dev/null || true
./scripts/feeds install -p small simple-obfs 2>/dev/null || true
./scripts/feeds install -p small v2ray-core 2>/dev/null || true
./scripts/feeds install -p small xray-core 2>/dev/null || true
./scripts/feeds install -p small trojan-plus 2>/dev/null || true

# DNS 相关
./scripts/feeds install -p small mosdns 2>/dev/null || true
./scripts/feeds install -p small luci-app-mosdns 2>/dev/null || true
./scripts/feeds install -p small luci-app-smartdns 2>/dev/null || true
./scripts/feeds install -p small smartdns 2>/dev/null || true

echo "=== Package installation completed ==="

# ┌─────────────────────────────────────────────┐
# │           虚拟机网络优化                      │
# └─────────────────────────────────────────────┘
echo ">>> Applying VM network optimizations..."

mkdir -p files/etc/sysctl.d
cat > files/etc/sysctl.d/99-vm-optimize.conf <<'EOF'
# TCP BBR
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# TCP Fast Open
net.ipv4.tcp_fastopen = 3

# 连接优化
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 600

# 转发
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# 内存优化
vm.swappiness = 10
EOF

echo "Network optimizations applied."

# ┌─────────────────────────────────────────────┐
# │           创建版本信息                        │
# └─────────────────────────────────────────────┘
mkdir -p files/etc
cat > files/etc/openwrt_optimized <<EOF
EDITION=VM-Optimized
KERNEL=6.12
TARGET=x86_64
BUILD_DATE=$(date +%Y%m%d)
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
echo "内核: 6.12"
echo "代理: SSR-Plus + Xray"
echo "DNS:  MosDNS + SmartDNS"
echo "优化: TCP BBR + Fast Open"
echo ""
echo "======================================"
