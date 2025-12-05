#!/bin/bash
# DNS性能基准测试脚本

echo "======================================"
echo "    AdGuard Home DNS性能测试"
echo "======================================"
echo ""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 测试参数
DNS_SERVER="127.0.0.1"
TEST_COUNT=100
PARALLEL_QUERIES=10

# 测试域名列表（混合国内外）
DOMAINS=(
    # 国内热门
    "www.baidu.com"
    "www.taobao.com"
    "www.qq.com"
    "www.jd.com"
    "www.bilibili.com"
    "www.douyin.com"
    "www.163.com"
    "www.sina.com.cn"
    # 国外
    "www.google.com"
    "www.youtube.com"
    "www.facebook.com"
    "www.github.com"
    "www.stackoverflow.com"
    "www.wikipedia.org"
    "www.reddit.com"
    "www.amazon.com"
)

# 1. 单查询延迟测试
echo -e "${YELLOW}1. 单查询延迟测试${NC}"
echo "-------------------"
TOTAL_TIME=0
SUCCESS_COUNT=0
MIN_TIME=9999
MAX_TIME=0

for domain in "${DOMAINS[@]}"; do
    # 使用dig测试
    RESULT=$(dig @$DNS_SERVER $domain +noall +stats 2>/dev/null | grep "Query time" | awk '{print $4}')
    
    if [ -n "$RESULT" ]; then
        printf "%-30s: " "$domain"
        
        # 统计
        TOTAL_TIME=$((TOTAL_TIME + RESULT))
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        
        if [ $RESULT -lt $MIN_TIME ]; then
            MIN_TIME=$RESULT
        fi
        if [ $RESULT -gt $MAX_TIME ]; then
            MAX_TIME=$RESULT
        fi
        
        # 颜色显示
        if [ $RESULT -le 20 ]; then
            echo -e "${GREEN}${RESULT} ms${NC}"
        elif [ $RESULT -le 50 ]; then
            echo -e "${YELLOW}${RESULT} ms${NC}"
        else
            echo -e "${RED}${RESULT} ms${NC}"
        fi
    else
        printf "%-30s: ${RED}FAIL${NC}\n" "$domain"
    fi
done

# 计算平均值
if [ $SUCCESS_COUNT -gt 0 ]; then
    AVG_TIME=$((TOTAL_TIME / SUCCESS_COUNT))
    echo ""
    echo -e "${BLUE}统计结果：${NC}"
    echo "  成功率: $SUCCESS_COUNT/${#DOMAINS[@]}"
    echo "  平均延迟: ${AVG_TIME} ms"
    echo "  最快: ${MIN_TIME} ms"
    echo "  最慢: ${MAX_TIME} ms"
fi

# 2. 缓存命中测试
echo ""
echo -e "${YELLOW}2. 缓存命中测试${NC}"
echo "----------------"
TEST_DOMAIN="www.baidu.com"

# 第一次查询（冷缓存）
COLD_TIME=$(dig @$DNS_SERVER $TEST_DOMAIN +noall +stats 2>/dev/null | grep "Query time" | awk '{print $4}')
echo "  冷缓存查询: ${COLD_TIME} ms"

# 第二次查询（热缓存）
HOT_TIME=$(dig @$DNS_SERVER $TEST_DOMAIN +noall +stats 2>/dev/null | grep "Query time" | awk '{print $4}')
echo "  热缓存查询: ${HOT_TIME} ms"

if [ -n "$COLD_TIME" ] && [ -n "$HOT_TIME" ]; then
    if [ $HOT_TIME -lt $COLD_TIME ]; then
        IMPROVEMENT=$(( (COLD_TIME - HOT_TIME) * 100 / COLD_TIME ))
        echo -e "  ${GREEN}缓存生效！性能提升: ${IMPROVEMENT}%${NC}"
    else
        echo -e "  ${YELLOW}缓存可能未生效${NC}"
    fi
fi

# 3. 并发查询测试
echo ""
echo -e "${YELLOW}3. 并发查询测试（${PARALLEL_QUERIES}个并发）${NC}"
echo "--------------------------------"

# 开始时间
START_TIME=$(date +%s%N)

# 并发查询
for i in $(seq 1 $PARALLEL_QUERIES); do
    (
        DOMAIN=${DOMAINS[$((i % ${#DOMAINS[@]}))]}
        dig @$DNS_SERVER $DOMAIN +short > /dev/null 2>&1
    ) &
done

# 等待所有查询完成
wait

# 结束时间
END_TIME=$(date +%s%N)
DURATION=$((($END_TIME - $START_TIME) / 1000000))

echo "  完成${PARALLEL_QUERIES}个并发查询耗时: ${DURATION} ms"
AVG_PARALLEL=$((DURATION / PARALLEL_QUERIES))
echo "  平均每个查询: ${AVG_PARALLEL} ms"

# 4. 压力测试
echo ""
echo -e "${YELLOW}4. 压力测试（${TEST_COUNT}次连续查询）${NC}"
echo "-----------------------------------"

START_TIME=$(date +%s)
FAIL_COUNT=0

for i in $(seq 1 $TEST_COUNT); do
    DOMAIN=${DOMAINS[$((i % ${#DOMAINS[@]}))]}
    if ! dig @$DNS_SERVER $DOMAIN +short > /dev/null 2>&1; then
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    # 显示进度
    if [ $((i % 10)) -eq 0 ]; then
        echo -ne "\r  进度: $i/$TEST_COUNT"
    fi
done

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
QPS=$((TEST_COUNT / DURATION))

echo ""
echo "  总耗时: ${DURATION} 秒"
echo "  成功率: $((TEST_COUNT - FAIL_COUNT))/${TEST_COUNT}"
echo "  QPS: ${QPS} 查询/秒"

# 5. Docker资源使用（如果是Docker环境）
if docker ps | grep -q adguardhome; then
    echo ""
    echo -e "${YELLOW}5. Docker容器资源使用${NC}"
    echo "---------------------"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" adguardhome
fi

# 性能评级
echo ""
echo "======================================"
echo -e "${BLUE}性能评级：${NC}"

if [ -n "$AVG_TIME" ]; then
    if [ $AVG_TIME -le 20 ]; then
        echo -e "${GREEN}★★★★★ 优秀（平均<20ms）${NC}"
    elif [ $AVG_TIME -le 50 ]; then
        echo -e "${GREEN}★★★★☆ 良好（平均20-50ms）${NC}"
    elif [ $AVG_TIME -le 100 ]; then
        echo -e "${YELLOW}★★★☆☆ 一般（平均50-100ms）${NC}"
    else
        echo -e "${RED}★★☆☆☆ 需要优化（平均>100ms）${NC}"
    fi
fi

echo ""
echo "优化建议："
if [ $AVG_TIME -gt 50 ]; then
    echo "  - 检查网络连接质量"
    echo "  - 增加缓存大小"
    echo "  - 优化上游DNS服务器"
    echo "  - 使用host网络模式"
else
    echo "  - 性能表现良好！"
fi
echo "======================================" 
