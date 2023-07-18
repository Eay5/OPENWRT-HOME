# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

#new
# sed -i '$a src-git small8 https://github.com/kenzok8/small-package' feeds.conf.default
# sed -i '$a src-git smallpasswall https://github.com/kenzok8/small' feeds.conf.default
# #stable
# sed -i '$a src-git kenzok8 https://github.com/kenzok8/openwrt-packages.git' feeds.conf.default
# sed -i '$a src-git passwall https://github.com/xiaorouji/openwrt-passwall.git' feeds.conf.default
sed -i '$a src-git NueXini_Packages https://github.com/NueXini/NueXini_Packages.git' feeds.conf.default
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git luci-theme-argon
# # sed -i '$a src-git darkmatter https://github.com/apollo-ng/luci-theme-darkmatter.git' feeds.conf.default
# # git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argonenew
# #ddns-go
# git clone https://github.com/sirpdboy/luci-app-ddns-go.git package/ddns-go
# #smartdns
# #git clone https://github.com/pymumu/smartdns.git package/smartdns
# #git clone https://github.com/pymumu/luci-app-smartdns.git package/luci-app-smartdns
