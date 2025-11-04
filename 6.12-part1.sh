sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small-package' feeds.conf.default

# 删除冲突的包
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/lang/golang

# 删除官方的 shadowsocks-libev 以使用 small 源的版本
rm -rf feeds/packages/net/shadowsocks-libev

# 添加自定义 Golang 包以解决依赖问题
git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang

# 删除有循环依赖的冲突包，防止构建失败
echo "Removing conflicting packages with circular dependencies..."
rm -rf feeds/luci/applications/luci-app-fchomo
rm -rf feeds/luci/applications/luci-app-bypass
rm -rf feeds/kenzo/luci-app-fchomo
rm -rf feeds/kenzo/luci-app-bypass
rm -rf feeds/small/luci-app-fchomo
rm -rf feeds/small/luci-app-bypass

# 根据kenzok8/small-package README建议，删除可能冲突的插件
rm -rf feeds/small/{base-files,dnsmasq,firewall*,fullconenat,libnftnl,nftables,ppp,opkg,ucl,upx,vsftpd*,miniupnpd-iptables,wireless-regdb}

echo "Conflicting packages removed."