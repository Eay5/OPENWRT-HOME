# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

#new
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/Eay5/small.git' feeds.conf.default
./scripts/feeds update -a && rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/{alist,adguardhome,xray*,v2ray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang feeds/packages/lang/golang
./scripts/feeds install -a 
# git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git luci-theme-argon
# # sed -i '$a src-git darkmatter https://github.com/apollo-ng/luci-theme-darkmatter.git' feeds.conf.default
# # git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argonenew
# #ddns-go
# pushd feeds/packages/lang
# git clone https://github.com/sirpdboy/luci-app-ddns-go.git package/ddns-go
# #smartdns
# #git clone https://github.com/pymumu/smartdns.git package/smartdns
# #git clone https://github.com/pymumu/luci-app-smartdns.git package/luci-app-smartdns
