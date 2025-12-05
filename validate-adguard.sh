#!/bin/bash
# AdGuard Home 配置验证脚本

echo "======================================"
echo "  AdGuard Home 配置验证"
echo "======================================"
echo ""

CONFIG_FILE="adguard-optimized.yaml"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查YAML语法
echo -e "${YELLOW}1. 检查YAML语法...${NC}"
if command -v yq &> /dev/null; then
    if yq eval '.' "$CONFIG_FILE" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ YAML语法正确${NC}"
    else
        echo -e "${RED}✗ YAML语法错误${NC}"
        yq eval '.' "$CONFIG_FILE" 2>&1 | head -20
    fi
else
    echo "  (跳过：需要安装yq工具)"
fi

# 检查关键配置
echo ""
echo -e "${YELLOW}2. 检查关键配置...${NC}"

# 检查ratelimit_whitelist
echo -n "  检查ratelimit_whitelist: "
if grep -q "ratelimit_whitelist: \[\]" "$CONFIG_FILE"; then
    echo -e "${GREEN}✓ 已修复（空列表）${NC}"
else
    echo -e "${RED}✗ 可能有问题${NC}"
    grep "ratelimit_whitelist:" "$CONFIG_FILE" -A 2
fi

# 检查upstream_mode
echo -n "  检查upstream_mode: "
if grep -q "upstream_mode: parallel" "$CONFIG_FILE"; then
    echo -e "${GREEN}✓ 并行模式${NC}"
else
    echo -e "${YELLOW}⚠ 非并行模式${NC}"
    grep "upstream_mode:" "$CONFIG_FILE"
fi

# 检查upstream_timeout
echo -n "  检查upstream_timeout: "
if grep -q "upstream_timeout: 3s" "$CONFIG_FILE"; then
    echo -e "${GREEN}✓ 3秒超时${NC}"
else
    echo -e "${YELLOW}⚠ 超时时间可能过长${NC}"
    grep "upstream_timeout:" "$CONFIG_FILE"
fi

# 检查HTTP端口
echo -n "  检查HTTP端口: "
HTTP_PORT=$(grep "address: 0.0.0.0:" "$CONFIG_FILE" | awk -F: '{print $3}')
echo -e "${GREEN}端口: $HTTP_PORT${NC}"

# 检查DNS端口
echo -n "  检查DNS端口: "
if grep -q "port: 53" "$CONFIG_FILE"; then
    echo -e "${GREEN}✓ 53端口${NC}"
else
    echo -e "${RED}✗ DNS端口不是53${NC}"
fi

# 统计DNS服务器数量
echo ""
echo -e "${YELLOW}3. DNS服务器统计...${NC}"
echo "  本地电信DNS: $(grep -c "202\.103\." "$CONFIG_FILE") 个"
echo "  腾讯DNS: $(grep -c "119\.2[89]\." "$CONFIG_FILE") 个"
echo "  阿里DNS: $(grep -c "223\.[56]\." "$CONFIG_FILE") 个"
echo "  百度DNS: $(grep -c "180\.76\." "$CONFIG_FILE") 个"
echo "  海外DNS: $(grep -c "https://.*dns-query" "$CONFIG_FILE") 个"

# 检查问题DNS
echo ""
echo -e "${YELLOW}4. 检查问题DNS服务器...${NC}"
if grep -q "180.184.2.2" "$CONFIG_FILE"; then
    echo -e "${YELLOW}⚠ 发现180.184.2.2（日志显示此DNS超时）${NC}"
    echo "  建议：考虑移除或降低优先级"
else
    echo -e "${GREEN}✓ 未发现问题DNS${NC}"
fi

# 建议
echo ""
echo "======================================"
echo -e "${YELLOW}建议操作：${NC}"
echo "1. 重启AdGuard Home服务："
echo "   systemctl restart AdGuardHome"
echo ""
echo "2. 查看实时日志："
echo "   journalctl -fu AdGuardHome"
echo ""
echo "3. 如果仍有问题，尝试移除超时的DNS："
echo "   编辑配置文件，注释掉180.184.2.2等超时DNS"
echo ""
echo "4. 测试DNS解析："
echo "   dig @127.0.0.1 www.baidu.com"
echo "======================================"
