#!/bin/bash
# 电信DNS性能测试脚本

echo "======================================"
echo "   电信宽带 DNS 性能测试"  
echo "======================================"
echo ""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 测试域名列表
DOMAINS=(
    "www.baidu.com"
    "www.taobao.com"
    "www.qq.com"
    "www.163.com"
    "www.sohu.com"
    "github.com"
    "www.google.com"
    "www.youtube.com"
)

# DNS服务器列表
declare -A DNS_SERVERS
DNS_SERVERS["电信1"]="202.103.24.68"
DNS_SERVERS["电信2"]="202.103.44.150"
DNS_SERVERS["电信3"]="202.103.0.68"
DNS_SERVERS["电信4"]="202.103.0.117"
DNS_SERVERS["阿里DNS"]="223.5.5.5"
DNS_SERVERS["腾讯DNS"]="119.29.29.29"
DNS_SERVERS["114DNS"]="114.114.114.114"
DNS_SERVERS["谷歌DNS"]="8.8.8.8"

# 测试函数
test_dns() {
    local dns_name=$1
    local dns_ip=$2
    local domain=$3
    
    # 使用dig测试，超时2秒
    result=$(dig @$dns_ip $domain +time=2 +tries=1 +noall +stats 2>/dev/null | grep "Query time" | awk '{print $4}')
    
    if [ -n "$result" ]; then
        echo "$result"
    else
        echo "TIMEOUT"
    fi
}

# 测试所有DNS服务器
echo -e "${BLUE}测试域名：${NC}"
for domain in "${DOMAINS[@]}"; do
    echo "  - $domain"
done
echo ""

echo -e "${GREEN}开始测试...${NC}"
echo ""

# 存储结果
declare -A RESULTS
declare -A TOTALS
declare -A COUNTS

# 初始化统计
for dns_name in "${!DNS_SERVERS[@]}"; do
    TOTALS[$dns_name]=0
    COUNTS[$dns_name]=0
done

# 执行测试
for domain in "${DOMAINS[@]}"; do
    echo -e "${YELLOW}测试域名: $domain${NC}"
    printf "%-15s %-20s %s\n" "DNS服务器" "IP地址" "响应时间(ms)"
    echo "----------------------------------------"
    
    for dns_name in "${!DNS_SERVERS[@]}"; do
        dns_ip=${DNS_SERVERS[$dns_name]}
        response_time=$(test_dns "$dns_name" "$dns_ip" "$domain")
        
        if [ "$response_time" != "TIMEOUT" ]; then
            printf "%-15s %-20s " "$dns_name" "$dns_ip"
            if [ $response_time -le 50 ]; then
                echo -e "${GREEN}${response_time} ms${NC}"
            elif [ $response_time -le 100 ]; then
                echo -e "${YELLOW}${response_time} ms${NC}"
            else
                echo -e "${RED}${response_time} ms${NC}"
            fi
            TOTALS[$dns_name]=$((TOTALS[$dns_name] + response_time))
            COUNTS[$dns_name]=$((COUNTS[$dns_name] + 1))
        else
            printf "%-15s %-20s ${RED}TIMEOUT${NC}\n" "$dns_name" "$dns_ip"
        fi
    done
    echo ""
done

# 显示统计结果
echo "======================================"
echo -e "${BLUE}平均响应时间统计：${NC}"
echo "======================================"
printf "%-15s %-20s %-12s %s\n" "DNS服务器" "IP地址" "平均响应(ms)" "成功率"
echo "--------------------------------------------------------"

# 计算并排序平均值
declare -A AVERAGES
for dns_name in "${!DNS_SERVERS[@]}"; do
    if [ ${COUNTS[$dns_name]} -gt 0 ]; then
        avg=$((TOTALS[$dns_name] / COUNTS[$dns_name]))
        success_rate=$((COUNTS[$dns_name] * 100 / ${#DOMAINS[@]}))
        AVERAGES[$dns_name]="$avg:$success_rate"
    else
        AVERAGES[$dns_name]="9999:0"
    fi
done

# 排序并显示
for dns_name in $(for k in "${!AVERAGES[@]}"; do 
    echo "$k:${AVERAGES[$k]}" 
done | sort -t: -k2 -n | cut -d: -f1); do
    dns_ip=${DNS_SERVERS[$dns_name]}
    IFS=':' read -r avg success <<< "${AVERAGES[$dns_name]}"
    
    if [ "$avg" != "9999" ]; then
        printf "%-15s %-20s " "$dns_name" "$dns_ip"
        if [ $avg -le 50 ]; then
            echo -e "${GREEN}${avg} ms${NC}         ${success}%"
        elif [ $avg -le 100 ]; then
            echo -e "${YELLOW}${avg} ms${NC}         ${success}%"
        else
            echo -e "${RED}${avg} ms${NC}         ${success}%"
        fi
    else
        printf "%-15s %-20s ${RED}N/A${NC}           0%%\n" "$dns_name" "$dns_ip"
    fi
done

echo ""
echo "======================================"
echo -e "${GREEN}测试完成！${NC}"
echo ""
echo "建议："
echo "  - 绿色 (≤50ms): 优秀"
echo "  - 黄色 (50-100ms): 良好"
echo "  - 红色 (>100ms): 较慢"
echo ""
echo "根据测试结果，你的电信DNS表现应该是最好的。"
