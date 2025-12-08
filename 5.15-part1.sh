#!/bin/bash
# 5.15-part1.sh - 在 feeds update 之前执行
# 配置第三方源并处理依赖

echo "Adding custom feeds..."

# 添加第三方源
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small-package' feeds.conf.default
sed -i '3i src-git helloworld https://github.com/fw876/helloworld' feeds.conf.default

echo "Custom feeds added to feeds.conf.default"
cat feeds.conf.default

echo "Part1 completed. Feeds will be configured after update." 
