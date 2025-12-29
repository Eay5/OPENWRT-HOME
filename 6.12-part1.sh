#!/bin/bash
# 6.12-part1.sh - 在 feeds update 之前执行
# 配置第三方源并处理依赖

echo "======================================"
echo "Adding custom feeds..."
echo "======================================"

# 备份原始 feeds.conf.default
cp feeds.conf.default feeds.conf.default.bak

# 添加第三方源（使用稳定的源）
cat >> feeds.conf.default << 'EOF'
src-git kenzo https://github.com/kenzok8/openwrt-packages
src-git small https://github.com/kenzok8/small-package
src-git helloworld https://github.com/fw876/helloworld
EOF

echo "Custom feeds added to feeds.conf.default"
echo "======================================"
cat feeds.conf.default
echo "======================================"

echo "Part1 completed. Feeds will be configured after update."
