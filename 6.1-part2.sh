#ip
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate
# 编译6.1
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=6.1/g' target/linux/x86/Makefile
#2. Clear the login password
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings
#4.an-theme
#取消bootstrap为默认主题：
sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' feeds/luci/collections/luci/Makefile
#name
sed -i "s/hostname='LEDE'/hostname='EAY'/g" package/base-files/files/bin/config_generate

# 验证关键包是否存在
echo "=== Verifying critical packages ==="

# 检查 SSR-Plus 相关包
if [ -d "feeds/helloworld/luci-app-ssr-plus" ]; then
    echo "✓ luci-app-ssr-plus found in helloworld feed"
elif [ -d "feeds/small/luci-app-ssr-plus" ]; then
    echo "✓ luci-app-ssr-plus found in small feed"
else
    echo "✗ WARNING: luci-app-ssr-plus NOT found in any feed!"
fi

# 检查 shadowsocks-libev
if [ -d "feeds/helloworld/shadowsocks-libev" ] || [ -d "feeds/small/shadowsocks-libev" ]; then
    echo "✓ shadowsocks-libev found"
else
    echo "✗ WARNING: shadowsocks-libev NOT found!"
fi

# 检查 mosdns
if [ -d "feeds/small/mosdns" ]; then
    echo "✓ mosdns found in small feed"
else
    echo "✗ WARNING: mosdns NOT found!"
fi

echo ""
echo "=== Installing packages ==="

# 特别确保关键包被安装
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

# 其他包从 small 源安装
./scripts/feeds install -p small shadowsocks-rust 2>/dev/null || true
./scripts/feeds install -p small shadowsocksr-libev 2>/dev/null || true
./scripts/feeds install -p small simple-obfs 2>/dev/null || true
./scripts/feeds install -p small v2ray-core 2>/dev/null || true
./scripts/feeds install -p small xray-core 2>/dev/null || true
./scripts/feeds install -p small trojan-plus 2>/dev/null || true
./scripts/feeds install -p small mosdns 2>/dev/null || true
./scripts/feeds install -p small luci-app-mosdns 2>/dev/null || true

echo "=== Package installation completed ==="
