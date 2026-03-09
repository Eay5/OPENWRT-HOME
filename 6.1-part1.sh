#!/bin/bash
# 6.1-part1.sh - 在 feeds update 之前执行
# 配置第三方源并处理依赖

echo "Adding custom feeds..."

# 添加第三方源（使用 small 而不是 small-package，与 lucky 版本一致）
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default

echo "Custom feeds added to feeds.conf.default"
cat feeds.conf.default

# 更新 feeds
./scripts/feeds update -a

# 删除冲突包（在 feeds update 后立即执行）
echo "Removing conflicting packages..."
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/lang/golang

# 添加自定义 Golang 包
git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang

# 删除有循环依赖的冲突包
rm -rf feeds/luci/applications/luci-app-fchomo
rm -rf feeds/luci/applications/luci-app-bypass
rm -rf feeds/kenzo/luci-app-fchomo
rm -rf feeds/kenzo/luci-app-bypass
rm -rf feeds/small/luci-app-fchomo
rm -rf feeds/small/luci-app-bypass

echo "Conflicting packages removed."
echo "Part1 completed."
