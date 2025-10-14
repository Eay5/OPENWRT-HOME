# 按照 kenzok8/small 仓库官方建议的一键命令
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default
./scripts/feeds update -a && rm -rf feeds/luci/applications/luci-app-mosdns

# 删除重复包以防止插件冲突（按官方建议）
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,smartdns}
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/lang/golang

# 使用 kenzok8 的 golang 1.25 仓库（兼容 xray-core、v2ray 等）
git clone https://github.com/kenzok8/golang -b 1.25 feeds/packages/lang/golang

# 安装所有 feeds
./scripts/feeds install -a

echo "SSR Plus 相关组件已准备就绪，可以开始编译..."