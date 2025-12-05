#!/bin/bash
# AdGuard Home 快速启动脚本

echo "======================================"
echo "  AdGuard Home 启动脚本"
echo "======================================"
echo ""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CONFIG_FILE="/opt/adguardhome/work/AdGuardHome.yaml"
OPTIMIZED_CONFIG="adguard-optimized.yaml"

# 1. 备份当前配置
echo -e "${YELLOW}1. 备份当前配置...${NC}"
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓ 配置已备份${NC}"
else
    echo -e "${YELLOW}⚠ 配置文件不存在，将创建新配置${NC}"
fi

# 2. 应用优化配置
echo -e "${YELLOW}2. 应用优化配置...${NC}"
if [ -f "$OPTIMIZED_CONFIG" ]; then
    cp "$OPTIMIZED_CONFIG" "$CONFIG_FILE"
    echo -e "${GREEN}✓ 优化配置已应用${NC}"
else
    echo -e "${RED}✗ 找不到优化配置文件：$OPTIMIZED_CONFIG${NC}"
    exit 1
fi

# 3. 检查配置文件权限
echo -e "${YELLOW}3. 设置文件权限...${NC}"
chmod 600 "$CONFIG_FILE"
chown adguardhome:adguardhome "$CONFIG_FILE" 2>/dev/null || true
echo -e "${GREEN}✓ 权限已设置${NC}"

# 4. 停止旧服务
echo -e "${YELLOW}4. 停止旧服务...${NC}"
if systemctl is-active --quiet AdGuardHome; then
    systemctl stop AdGuardHome
    echo -e "${GREEN}✓ 服务已停止${NC}"
else
    echo "  服务未运行"
fi

# 5. 清理缓存（可选）
echo -e "${YELLOW}5. 是否清理DNS缓存？(y/N)${NC}"
read -r -t 5 CLEAR_CACHE
if [[ "$CLEAR_CACHE" == "y" ]] || [[ "$CLEAR_CACHE" == "Y" ]]; then
    rm -rf /opt/adguardhome/work/data/querylog.json* 2>/dev/null
    rm -rf /opt/adguardhome/work/data/stats.db* 2>/dev/null
    echo -e "${GREEN}✓ 缓存已清理${NC}"
else
    echo "  跳过缓存清理"
fi

# 6. 启动服务
echo -e "${YELLOW}6. 启动AdGuard Home...${NC}"
systemctl start AdGuardHome

# 7. 检查启动状态
sleep 2
if systemctl is-active --quiet AdGuardHome; then
    echo -e "${GREEN}✓ AdGuard Home 启动成功！${NC}"
    echo ""
    echo "======================================"
    echo -e "${GREEN}服务已启动！${NC}"
    echo ""
    echo "访问地址："
    echo "  Web界面: http://$(hostname -I | awk '{print $1}'):3000"
    echo "  DNS端口: 53"
    echo ""
    echo "查看日志："
    echo "  journalctl -fu AdGuardHome"
    echo ""
    echo "测试DNS："
    echo "  dig @127.0.0.1 www.baidu.com"
    echo "======================================"
else
    echo -e "${RED}✗ 启动失败！${NC}"
    echo ""
    echo "查看错误日志："
    journalctl -xeu AdGuardHome | tail -20
    echo ""
    echo "恢复备份配置："
    echo "  cp ${CONFIG_FILE}.bak.* $CONFIG_FILE"
    echo "  systemctl restart AdGuardHome"
fi
