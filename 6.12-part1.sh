#!/bin/bash
# 6.12-part1.sh - 在 feeds update 之前执行
# 只修改 feeds.conf.default，添加第三方源

echo "Adding custom feeds..."

# 添加 kenzok8 源
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default

echo "Custom feeds added to feeds.conf.default"
cat feeds.conf.default

# 注意：feeds 目录在 feeds update 后才存在
# 删除操作已移至 workflow 的 feeds update 之后步骤

echo "Part1 completed. Feeds will be configured after update."