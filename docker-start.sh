#!/bin/bash
# AdGuard Home Docker 优化启动脚本

echo "======================================"
echo "  AdGuard Home Docker 性能优化启动"
echo "======================================"
echo ""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. 检查Docker
echo -e "${YELLOW}1. 检查Docker环境...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker未安装${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker已就绪${NC}"

# 2. 停止旧容器
echo -e "${YELLOW}2. 清理旧容器...${NC}"
docker stop adguardhome 2>/dev/null
docker rm adguardhome 2>/dev/null
echo -e "${GREEN}✓ 清理完成${NC}"

# 3. 创建目录
echo -e "${YELLOW}3. 创建工作目录...${NC}"
mkdir -p ./adguard-work ./adguard-conf
echo -e "${GREEN}✓ 目录已创建${NC}"

# 4. 复制配置
echo -e "${YELLOW}4. 应用优化配置...${NC}"
cp adguard-optimized.yaml ./adguard-work/AdGuardHome.yaml
echo -e "${GREEN}✓ 配置已应用${NC}"

# 5. 启动容器（优化版）
echo -e "${YELLOW}5. 启动优化容器...${NC}"

# 检查是否可以使用host网络
if [ "$1" == "--host" ]; then
    echo "  使用host网络模式..."
    docker run -d \
        --name adguardhome \
        --restart unless-stopped \
        --network host \
        --cap-add NET_ADMIN \
        --cap-add NET_BIND_SERVICE \
        --cap-add NET_RAW \
        --cap-add SYS_TIME \
        --sysctl net.core.somaxconn=65535 \
        --sysctl net.ipv4.tcp_tw_reuse=1 \
        --sysctl net.ipv4.tcp_fin_timeout=30 \
        --sysctl net.ipv4.tcp_max_syn_backlog=8192 \
        --sysctl net.ipv4.tcp_fastopen=3 \
        --sysctl net.core.netdev_max_backlog=5000 \
        --sysctl net.core.rmem_max=134217728 \
        --sysctl net.core.wmem_max=134217728 \
        --ulimit nofile=65535:65535 \
        --memory="1g" \
        --memory-reservation="256m" \
        --cpus="2" \
        -e TZ=Asia/Shanghai \
        -e GOGC=100 \
        -e GOMEMLIMIT=800MiB \
        -e GOMAXPROCS=4 \
        -v "$(pwd)/adguard-work:/opt/adguardhome/work" \
        -v "$(pwd)/adguard-conf:/opt/adguardhome/conf" \
        --tmpfs /tmp:size=100M \
        --log-opt max-size=10m \
        --log-opt max-file=3 \
        adguard/adguardhome:latest
else
    echo "  使用bridge网络模式..."
    docker run -d \
        --name adguardhome \
        --restart unless-stopped \
        -p 53:53/tcp \
        -p 53:53/udp \
        -p 3000:3000/tcp \
        -p 853:853/tcp \
        --cap-add NET_ADMIN \
        --cap-add NET_BIND_SERVICE \
        --cap-add NET_RAW \
        --cap-add SYS_TIME \
        --sysctl net.core.somaxconn=65535 \
        --sysctl net.ipv4.tcp_tw_reuse=1 \
        --sysctl net.ipv4.tcp_fin_timeout=30 \
        --sysctl net.ipv4.tcp_max_syn_backlog=8192 \
        --sysctl net.ipv4.tcp_fastopen=3 \
        --sysctl net.core.netdev_max_backlog=5000 \
        --sysctl net.core.rmem_max=134217728 \
        --sysctl net.core.wmem_max=134217728 \
        --ulimit nofile=65535:65535 \
        --memory="1g" \
        --memory-reservation="256m" \
        --cpus="2" \
        -e TZ=Asia/Shanghai \
        -e GOGC=100 \
        -e GOMEMLIMIT=800MiB \
        -e GOMAXPROCS=4 \
        -v "$(pwd)/adguard-work:/opt/adguardhome/work" \
        -v "$(pwd)/adguard-conf:/opt/adguardhome/conf" \
        --tmpfs /tmp:size=100M \
        --log-opt max-size=10m \
        --log-opt max-file=3 \
        adguard/adguardhome:latest
fi

# 6. 等待启动
echo -e "${YELLOW}6. 等待服务启动...${NC}"
sleep 5

# 7. 检查状态
if docker ps | grep -q adguardhome; then
    echo -e "${GREEN}✓ AdGuard Home启动成功！${NC}"
    echo ""
    echo "======================================"
    echo -e "${GREEN}容器运行状态：${NC}"
    docker ps --filter name=adguardhome --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo -e "${BLUE}资源使用：${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" adguardhome
    echo ""
    echo -e "${BLUE}访问地址：${NC}"
    echo "  Web界面: http://$(hostname -I | awk '{print $1}'):3000"
    echo "  DNS服务: $(hostname -I | awk '{print $1}'):53"
    echo ""
    echo -e "${BLUE}查看日志：${NC}"
    echo "  docker logs -f adguardhome"
    echo ""
    echo -e "${BLUE}性能监控：${NC}"
    echo "  docker stats adguardhome"
    echo "======================================"
else
    echo -e "${RED}✗ 启动失败！${NC}"
    echo "查看错误日志："
    docker logs adguardhome --tail 50
fi
