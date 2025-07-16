sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default
./scripts/feeds update -a && rm -rf feeds/luci/applications/luci-app-mosdns
# 删除不需要的包，但保留 v2ray 和 xray (SSR Plus+ 需要)
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,smartdns}
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/lang/golang

# 添加自定义 Golang 包以解决依赖问题
git clone https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang

# 确保 SSR Plus+ 核心组件可用
./scripts/feeds install -a -p small
./scripts/feeds install -a -p kenzo

# 安装 SSR Plus+ 必需的核心包
./scripts/feeds install -p packages shadowsocks-libev
./scripts/feeds install -p small shadowsocksr-libev
./scripts/feeds install -p small v2ray-core
./scripts/feeds install -p small xray-core
./scripts/feeds install -p small trojan-plus
./scripts/feeds install -p small trojan-go
./scripts/feeds install -p small naiveproxy
