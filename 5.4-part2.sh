#ip
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate

# 编译5.10
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=5.4/g' target/linux/x86/Makefile
#2. Clear the login password
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings
#4.an-theme
#取消bootstrap为默认主题：
sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' feeds/luci/collections/luci/Makefile
#name
sed -i "/option hostname/s/'LEDE'/'EAY'/" package/base-files/files/etc/config/system

sed -i "s/hostname='LEDE'/hostname='EAY'/g" package/base-files/files/bin/config_generate

# 验证关键包是否存在
echo "=== Verifying critical packages ==="

if [ -d "feeds/helloworld/luci-app-ssr-plus" ]; then
    echo "✓ luci-app-ssr-plus found in helloworld feed"
elif [ -d "feeds/small/luci-app-ssr-plus" ]; then
    echo "✓ luci-app-ssr-plus found in small feed"
else
    echo "✗ WARNING: luci-app-ssr-plus NOT found!"
fi

echo ""
echo "=== Installing packages ==="

./scripts/feeds install -p helloworld luci-app-ssr-plus 2>/dev/null || \
    ./scripts/feeds install -p small luci-app-ssr-plus 2>/dev/null || true
./scripts/feeds install -p helloworld shadowsocks-libev 2>/dev/null || \
    ./scripts/feeds install -p small shadowsocks-libev 2>/dev/null || true
./scripts/feeds install -p helloworld shadowsocks-libev-ss-server 2>/dev/null || \
    ./scripts/feeds install -p small shadowsocks-libev-ss-server 2>/dev/null || true
./scripts/feeds install -p helloworld shadowsocks-libev-ss-redir 2>/dev/null || \
    ./scripts/feeds install -p small shadowsocks-libev-ss-redir 2>/dev/null || true
./scripts/feeds install -p helloworld shadowsocks-libev-ss-local 2>/dev/null || \
    ./scripts/feeds install -p small shadowsocks-libev-ss-local 2>/dev/null || true
./scripts/feeds install -p small shadowsocks-rust 2>/dev/null || true
./scripts/feeds install -p small shadowsocksr-libev 2>/dev/null || true
./scripts/feeds install -p small simple-obfs 2>/dev/null || true
./scripts/feeds install -p small v2ray-core 2>/dev/null || true
./scripts/feeds install -p small xray-core 2>/dev/null || true
./scripts/feeds install -p small trojan-plus 2>/dev/null || true
./scripts/feeds install -p small mosdns 2>/dev/null || true
./scripts/feeds install -p small luci-app-mosdns 2>/dev/null || true

echo "=== Package installation completed ==="
