#!/bin/bash
# 配置验证脚本 - 编译前检查所有优化是否正确配置

echo "======================================"
echo "   OpenWrt 6.12 配置验证脚本"
echo "======================================"

ERRORS=0
WARNINGS=0

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查函数
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $2 存在"
        return 0
    else
        echo -e "${RED}✗${NC} $2 缺失: $1"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

check_config() {
    if grep -q "$1" "$2" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $3 已配置"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $3 未配置"
        WARNINGS=$((WARNINGS + 1))
        return 1
    fi
}

echo ""
echo "1. 检查核心文件..."
echo "-------------------"
check_file "6.12.config" "主配置文件"
check_file "6.12-part1.sh" "Part1脚本"
check_file "6.12-part2.sh" "Part2脚本"
check_file ".github/workflows/6.12-openwrt.yml" "GitHub Actions工作流"

echo ""
echo "2. 检查优化脚本..."
echo "-------------------"
check_file "files/etc/init.d/ssr-optimization" "SSR优化启动脚本"
check_file "files/etc/sysctl.d/99-ssr-plus-optimization.conf" "Sysctl优化配置"
check_file "files/etc/hotplug.d/iface/99-dns-optimization" "DNS优化脚本"

echo ""
echo "3. 检查DNS配置文件..."
echo "---------------------"
check_file "files/etc/config/mosdns" "MosDNS配置"
check_file "files/etc/config/smartdns" "SmartDNS配置"
check_file "files/etc/dnsmasq.d/99-dns-optimization.conf" "dnsmasq优化配置"

echo ""
echo "4. 验证关键配置项..."
echo "--------------------"
if [ -f "6.12.config" ]; then
    check_config "CONFIG_TARGET_x86_64=y" "6.12.config" "x86_64平台"
    check_config "CONFIG_PACKAGE_luci-app-ssr-plus=y" "6.12.config" "SSR-Plus"
    check_config "CONFIG_PACKAGE_luci-app-mosdns=y" "6.12.config" "MosDNS"
    check_config "CONFIG_PACKAGE_luci-app-smartdns=y" "6.12.config" "SmartDNS"
    check_config "CONFIG_PACKAGE_kmod-tcp-bbr=y" "6.12.config" "BBR拥塞控制"
    check_config "CONFIG_PACKAGE_kmod-virtio-net=y" "6.12.config" "VirtIO网络"
    check_config "CONFIG_SHADOWSOCKS_RUST_THREADS=8" "6.12.config" "8线程优化"
    check_config "CONFIG_KERNEL_TRANSPARENT_HUGEPAGE=y" "6.12.config" "透明大页"
    check_config "CONFIG_PACKAGE_kmod-kvm-intel=y" "6.12.config" "Intel VT-x"
fi

echo ""
echo "5. 检查潜在问题..."
echo "------------------"
# 检查是否有重复配置
if [ -f "6.12.config" ]; then
    duplicates=$(sort 6.12.config | grep "^CONFIG_" | uniq -d)
    if [ -n "$duplicates" ]; then
        echo -e "${RED}✗${NC} 发现重复配置项:"
        echo "$duplicates"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✓${NC} 无重复配置项"
    fi
fi

# 检查冲突包
if [ -f "6.12.config" ]; then
    if grep -q "CONFIG_PACKAGE_luci-app-passwall=y" 6.12.config && \
       grep -q "CONFIG_PACKAGE_luci-app-ssr-plus=y" 6.12.config; then
        echo -e "${RED}✗${NC} Passwall和SSR-Plus同时启用（冲突）"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✓${NC} 无代理工具冲突"
    fi
fi

echo ""
echo "======================================"
echo "验证结果："
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ 所有配置正确！可以开始编译。${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ 有 $WARNINGS 个警告，但可以编译。${NC}"
    exit 0
else
    echo -e "${RED}✗ 发现 $ERRORS 个错误，$WARNINGS 个警告。${NC}"
    echo -e "${RED}请先修复错误再编译！${NC}"
    exit 1
fi
