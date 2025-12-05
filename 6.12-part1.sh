#!/bin/bash
# 6.12-part1.sh - 在 feeds update 之前执行
# 只修改 feeds.conf.default，添加第三方源

echo "Adding custom feeds..."

# 添加必要的第三方源 (精简版)
sed -i '1i src-git helloworld https://github.com/fw876/helloworld' feeds.conf.default
sed -i '2i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default

echo "Custom feeds added to feeds.conf.default"
cat feeds.conf.default

echo "Part1 completed. Feeds will be configured after update."