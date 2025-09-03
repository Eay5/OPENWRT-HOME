sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default
./scripts/feeds update -a && rm -rf feeds/luci/applications/luci-app-mosdns
# 删除不需要的包，但保留 v2ray 和 xray (SSR Plus+ 需要)
rm -rf feeds/packages/net/{alist,adguardhome,mosdns}
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/lang/golang

# 升级系统Go版本到1.25.0以支持xray-core编译
echo "正在升级Go版本到1.25.0..."
cd /tmp
wget -q https://go.dev/dl/go1.25.0.linux-amd64.tar.gz
echo "2852af0cb20a13139b3448992e69b868e50ed0f8a1e5940ee1de9e19a123b613  go1.25.0.linux-amd64.tar.gz" | sha256sum -c
if [ $? -eq 0 ]; then
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go1.25.0.linux-amd64.tar.gz
    echo "Go 1.25.0 安装完成"
else
    echo "错误：Go包校验失败，请检查下载"
    exit 1
fi
cd - > /dev/null

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
