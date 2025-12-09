#!/bin/bash
# 6.6-part2.sh - OpenWrt 6.6 内核编译配置
# 在 feeds update 和 feeds install 之后执行

# 基础设置
echo "Applying basic settings..."

# 修改默认IP
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate

# 编译6.6内核
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=6.6/g' target/linux/x86/Makefile

# 修改主机名
sed -i "s/hostname='OpenWrt'/hostname='EAY'/g" package/base-files/files/bin/config_generate

# 取消bootstrap为默认主题，改为argone
sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

echo "Basic settings applied."

# 验证关键包
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

echo ""
echo "=== Installing packages ==="

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
./scripts/feeds install -p small mosdns 2>/dev/null || true
./scripts/feeds install -p small luci-app-mosdns 2>/dev/null || true
./scripts/feeds install -p small luci-app-smartdns 2>/dev/null || true
./scripts/feeds install -p small smartdns 2>/dev/null || true

echo "=== Package installation completed ==="

echo ""
echo "======================================"
echo "OpenWrt 6.6 配置完成！"
echo "======================================"
echo "配置信息："
echo "  - 内核: 6.6"
echo "  - 默认IP: 192.168.0.133"
echo "  - 主机名: EAY"
echo "  - 主题: Argon"
echo "  - 代理: SSR-Plus + MosDNS + SmartDNS"
echo "======================================"
