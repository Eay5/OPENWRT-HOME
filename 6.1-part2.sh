#!/bin/bash
# 6.1-part2.sh - OpenWrt 6.1 内核编译配置
# 在 feeds update 和 feeds install 之后执行

# 基础设置
echo "Applying basic settings..."

# 修改默认IP
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate

# 编译6.1内核
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=6.1/g' target/linux/x86/Makefile

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
echo "======================================"
echo "OpenWrt 6.1 配置完成！"
echo "======================================"
echo "配置信息："
echo "  - 内核: 6.1"
echo "  - 默认IP: 192.168.0.133"
echo "  - 主机名: EAY"
echo ""
echo "代理优化："
echo "  - SSR-Plus: Shadowsocks-Rust 高性能版"
echo "  - 支持: SS/SSR/V2ray/Xray/Trojan"
echo "  - 透明代理: redsocks2 + chinadns-ng"
echo ""
echo "DNS 优化："
echo "  - 主DNS: MosDNS (端口 5353)"
echo "    * GeoIP/GeoSite 分流"
echo "    * DoH/DoT 加密查询"
echo "  - 辅DNS: SmartDNS (端口 5354)"
echo "    * 多线路测速"
echo "    * 智能缓存"
echo "  - 工具: dig, drill, knot-dig"
echo ""
echo "网络优化："
echo "  - TCP: BBR + Hybla 拥塞控制"
echo "  - 加速: Shortcut-FE + Fast-Classifier"
echo "  - 监控: htop, iftop, iperf3, vnstat"
echo "======================================"
