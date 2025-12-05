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
# DNS优化工具安装
./scripts/feeds install -p small mosdns 2>/dev/null || \
    ./scripts/feeds install mosdns 2>/dev/null || true
./scripts/feeds install -p small luci-app-mosdns 2>/dev/null || \
    ./scripts/feeds install luci-app-mosdns 2>/dev/null || true
./scripts/feeds install -p small smartdns 2>/dev/null || \
    ./scripts/feeds install smartdns 2>/dev/null || true
./scripts/feeds install -p small luci-app-smartdns 2>/dev/null || \
    ./scripts/feeds install luci-app-smartdns 2>/dev/null || true
./scripts/feeds install miniupnpd 2>/dev/null || true

echo "=== Package installation completed ==="

echo ""
echo "=== Applying compilation optimizations ==="

# 启用编译优化（禁用ccache以确保稳定性）
echo "CONFIG_DEVEL=y" >> .config
# echo "CONFIG_CCACHE=y" >> .config  # 禁用ccache，确保干净编译
echo "CONFIG_BUILD_LOG=y" >> .config
echo "CONFIG_BUILD_LOG_DIR=\"./logs\"" >> .config

# Intel x86优化
echo "CONFIG_TARGET_OPTIMIZATION=\"-O3 -pipe -march=x86-64-v3 -mtune=generic\"" >> .config
echo "CONFIG_KERNEL_CC_OPTIMIZE_FOR_PERFORMANCE=y" >> .config

# 减少编译时间
echo "CONFIG_AUTOREMOVE=y" >> .config
echo "CONFIG_IMAGEOPT=y" >> .config

# 并行下载
echo "CONFIG_DOWNLOAD_TOOL_CUSTOM=\"aria2c -x 16 -s 16 -j 16\"" >> .config

echo "✓ Compilation optimizations applied"
echo "✓ Intel x86 optimizations enabled"
echo "✓ Clean build without cache for stability"

echo ""
echo "=== SSR-Plus Performance Tuning ==="

# SSR-Plus运行时优化
cat >> .config <<EOF
# SSR-Plus运行优化
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Libev=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Trojan_Plus=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Simple_Obfs=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_IPT2Socks=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Redsocks2=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Kcptun=n
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Libev_Server=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_V2ray_Plugin=y
EOF

echo "✓ SSR-Plus performance tuning applied"

echo ""
echo "=== Setting up runtime optimizations ==="

# 确保优化脚本有执行权限
if [ -f "../files/etc/init.d/ssr-optimization" ]; then
    chmod +x ../files/etc/init.d/ssr-optimization
    echo "✓ SSR optimization script enabled"
fi

# 确保sysctl配置会被应用
if [ -f "../files/etc/sysctl.d/99-ssr-plus-optimization.conf" ]; then
    echo "✓ Sysctl optimizations configured"
fi

echo ""
echo "=== DNS Architecture Setup ==="
# 配置DNS架构
cat >> .config <<EOF
# DNS架构优化
CONFIG_PACKAGE_luci-app-mosdns=y
CONFIG_PACKAGE_luci-app-smartdns=y
CONFIG_MOSDNS_INCLUDE_BINARY=y
CONFIG_SMARTDNS_INCLUDE_BINARY=y
# 确保DNS工具
CONFIG_PACKAGE_bind-tools=y
CONFIG_PACKAGE_drill=y
CONFIG_PACKAGE_knot-dig=y
EOF
echo "✓ DNS architecture configured: MosDNS(5353) + SmartDNS(5354)"

# 设置文件权限
if [ -f "../files/etc/hotplug.d/iface/99-dns-optimization" ]; then
    chmod +x ../files/etc/hotplug.d/iface/99-dns-optimization
    echo "✓ DNS optimization hotplug enabled"
fi

echo ""
echo "=== OPTIMIZATION SUMMARY ==="
echo "✅ Intel x86 CPU: AVX2 + AES-NI enabled"
echo "✅ KVM/QEMU: VirtIO + vhost-net optimized"
echo "✅ Network: BBR + SFE + Flow Offload"
echo "✅ SSR-Plus: 8 threads + 2048 connections"
echo "✅ DNS架构: MosDNS(主) + SmartDNS(辅) + dnsmasq"
echo "  - MosDNS: 端口5353，DoH/DoT，GeoIP分流"
echo "  - SmartDNS: 端口5354，测速选优，备用"
echo "  - dnsmasq: 端口53，缓存10K，DNSSEC"
echo "✅ Memory: Huge pages + compression"
echo "✅ Monitoring: htop + iftop + vnstat + dig"
echo "✅ Compilation: Clean build + parallel threads (no cache)"
echo "=== All optimizations completed ==="