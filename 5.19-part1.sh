# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default


sed -i '$a  src-git small8 https://github.com/kenzok8/small-package.git' feeds.conf.default
# sed -i '$a src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '$a src-git small https://github.com/kenzok8/small' feeds.conf.default
echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> "feeds.conf.default"
echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >> "feeds.conf.default"
# git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git luci-theme-argon
# # sed -i '$a src-git darkmatter https://github.com/apollo-ng/luci-theme-darkmatter.git' feeds.conf.default
# # git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argonenew
# #ddns-go
# git clone https://github.com/sirpdboy/luci-app-ddns-go.git package/ddns-go
# #smartdns
# #git clone https://github.com/pymumu/smartdns.git package/smartdns
# #git clone https://github.com/pymumu/luci-app-smartdns.git package/luci-app-smartdns
