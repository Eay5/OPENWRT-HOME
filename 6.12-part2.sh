#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 修改默认IP
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate

# 编译6.12内核
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=6.12/g' target/linux/x86/Makefile

# 清除登录密码
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings

# 取消bootstrap为默认主题，改为argone
sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' feeds/luci/collections/luci/Makefile

# 修改主机名
sed -i "s/hostname='LEDE'/hostname='EAY'/g" package/base-files/files/bin/config_generate

# 验证关键包是否存在
echo "=== Verifying critical packages ==="

# 检查 shadowsocks-rust 来源
if [ -d "feeds/small/shadowsocks-rust" ]; then
    echo "✓ shadowsocks-rust found in small feed"
else
    echo "✗ WARNING: shadowsocks-rust NOT found!"
fi

# 检查 shadowsocks-libev
if [ -d "feeds/small/shadowsocks-libev" ]; then
    echo "✓ shadowsocks-libev found in small feed"
else
    echo "✗ WARNING: shadowsocks-libev NOT found!"
fi

# 检查 luci-app-ssr-plus (检查多个源)
if [ -d "feeds/helloworld/luci-app-ssr-plus" ]; then
    echo "✓ luci-app-ssr-plus found in helloworld feed"
elif [ -d "feeds/small/luci-app-ssr-plus" ]; then
    echo "✓ luci-app-ssr-plus found in small feed"
else
    echo "✗ WARNING: luci-app-ssr-plus NOT found in any feed!"
fi

# 检查 mosdns
if [ -d "feeds/small/mosdns" ]; then
    echo "✓ mosdns found in small feed"
else
    echo "✗ WARNING: mosdns NOT found!"
fi

# 检查 simple-obfs
if [ -d "feeds/small/simple-obfs" ]; then
    echo "✓ simple-obfs found in small feed"
else
    echo "✗ WARNING: simple-obfs NOT found"
fi

# 检查 miniupnpd
if [ -d "feeds/packages/net/miniupnpd" ]; then
    echo "✓ miniupnpd found in packages feed"
else
    echo "⚠ miniupnpd not in packages feed, checking other feeds..."
fi

echo ""
echo "=== Installing packages ==="

# 重新安装所有 feeds (确保新添加的源生效)
./scripts/feeds install -a -f

# 特别确保关键包被安装（优先从 helloworld 安装 SSR-Plus，然后从 small 安装其他包）
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
    
./scripts/feeds install -p helloworld shadowsocks-libev-ss-tunnel 2>/dev/null || \
    ./scripts/feeds install -p small shadowsocks-libev-ss-tunnel 2>/dev/null || true

# 其他包从 small 或 kenzo 源安装
./scripts/feeds install -p small shadowsocks-rust 2>/dev/null || true
./scripts/feeds install -p small shadowsocksr-libev 2>/dev/null || true
./scripts/feeds install -p small simple-obfs 2>/dev/null || true
./scripts/feeds install -p small v2ray-core 2>/dev/null || true
./scripts/feeds install -p small xray-core 2>/dev/null || true
./scripts/feeds install -p small trojan-plus 2>/dev/null || true
./scripts/feeds install -p small mosdns 2>/dev/null || true
./scripts/feeds install -p small luci-app-mosdns 2>/dev/null || true
./scripts/feeds install miniupnpd 2>/dev/null || true

echo "=== Package installation completed ==="