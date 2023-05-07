# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# sed -i '$a src-git smallpackagenew https://github.com/Eay5/small-package-new.git' feeds.conf.default
sed -i '$a src-git smallpackage https://github.com/kenzok8/small-package' feeds.conf.default
sed -i '$a src-git smallpasswall https://github.com/kenzok8/small' feeds.conf.default
# sed -i '$a  src-git kenzok8 https://github.com/kenzok8/openwrt-packages.git' feeds.conf.default
# sed -i '$a src-git liuran001_packages https://github.com/liuran001/openwrt-packages' feeds.conf.default
# sed -i '$a src-git passwall https://github.com/xiaorouji/openwrt-passwall.git' feeds.conf.default

sed -i '$a src-git darkmatter https://github.com/apollo-ng/luci-theme-darkmatter.git' feeds.conf.default
#ddns-go
git clone https://github.com/sirpdboy/luci-app-ddns-go.git package/ddns-go
#smartdns
#git clone https://github.com/pymumu/smartdns.git package/smartdns
#git clone https://github.com/pymumu/luci-app-smartdns.git package/luci-app-smartdns
