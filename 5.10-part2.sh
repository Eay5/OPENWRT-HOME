#!/bin/bash
# 5.10-part2.sh - OpenWrt 5.10 内核编译配置
# 在 feeds install 之后执行

echo "Applying basic settings..."

# 修改默认IP
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate

# 编译5.10内核
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=5.10/g' target/linux/x86/Makefile

# 清空登录密码
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true

# 取消bootstrap为默认主题，改为argone
sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# 修改主机名
sed -i "s/hostname='LEDE'/hostname='EAY'/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='OpenWrt'/hostname='EAY'/g" package/base-files/files/bin/config_generate

echo "Basic settings applied."

# 验证关键包
echo ""
echo "=== Verifying critical packages ==="

if [ -d "feeds/kenzo/luci-app-ssr-plus" ] || [ -d "feeds/small/luci-app-ssr-plus" ]; then
    echo "✓ luci-app-ssr-plus found"
else
    echo "✗ WARNING: luci-app-ssr-plus NOT found!"
fi

if [ -d "feeds/kenzo/luci-app-mosdns" ] || [ -d "feeds/small/mosdns" ]; then
    echo "✓ MosDNS found"
else
    echo "✗ MosDNS not found"
fi

if [ -d "feeds/kenzo/luci-app-smartdns" ] || [ -d "feeds/small/smartdns" ]; then
    echo "✓ SmartDNS found"
else
    echo "✗ SmartDNS not found"
fi

echo ""
echo "======================================"
echo "OpenWrt 5.10 配置完成！"
echo "======================================"
echo "  - 内核: 5.10"
echo "  - 默认IP: 192.168.0.133"
echo "  - 主机名: EAY"
echo "  - 主题: Argon"
echo "======================================"
