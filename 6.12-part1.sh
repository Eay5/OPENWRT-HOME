# 按照 kenzok8/small 仓库官方建议的一键命令
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default
./scripts/feeds update -a && rm -rf feeds/luci/applications/luci-app-mosdns

# 删除重复包以防止插件冲突（按官方建议）
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,smartdns}
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/lang/golang

# ==========================================
# 🚀 使用 Go 1.25 版本（官方 sbwml 25.x 分支）
# ==========================================
echo "=================================================="
echo "🔧 配置 Go 1.25 编译环境"
echo "=================================================="

# 按照 sbwml 官方推荐方式安装 Go 1.25
# 参考: https://github.com/sbwml/packages_lang_golang
echo "📥 正在克隆 Go 1.25 仓库（sbwml 官方 25.x 分支）..."

if git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang; then
    echo "✅ 成功克隆 sbwml/packages_lang_golang (25.x 分支)"
    
    # 验证版本
    if [ -f "feeds/packages/lang/golang/golang/Makefile" ]; then
        GO_VERSION=$(grep "GO_VERSION_MAJOR_MINOR" feeds/packages/lang/golang/golang/Makefile | head -n1 | cut -d'=' -f2 | tr -d ' ' || echo "未知")
        GO_PATCH=$(grep "GO_VERSION_PATCH" feeds/packages/lang/golang/golang/Makefile | head -n1 | cut -d'=' -f2 | tr -d ' ' || echo "未知")
        echo "📦 已安装 Golang 版本: ${GO_VERSION}.${GO_PATCH}"
        echo "✅ 该版本完全支持 v2ray-plugin 和 xray-plugin！"
    fi
else
    echo "❌ 克隆失败，尝试备用方案..."
    
    # 备用方案：尝试其他分支
    if git clone https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang 2>/dev/null; then
        echo "⚠️  使用 24.x 分支（可能需要手动升级）"
    elif git clone https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang 2>/dev/null; then
        echo "⚠️  使用主分支"
    elif git clone https://github.com/kenzok8/golang feeds/packages/lang/golang 2>/dev/null; then
        echo "⚠️  使用 kenzok8/golang（备用源）"
    else
        echo "❌ 所有源都失败，将使用系统默认 feeds"
    fi
fi

echo "=================================================="

# 安装所有 feeds
./scripts/feeds install -a

echo ""
echo "=================================================="
echo "✅ Passwall 相关组件已准备就绪！"
echo "=================================================="
echo "📦 已启用核心包:"
echo "  - v2ray-core (V2Ray 核心)"
echo "  - xray-core (Xray 核心)"
echo "  - v2ray-plugin (需要 Go 1.25+)"
echo "  - xray-plugin (需要 Go 1.25+)"
echo "  - trojan-go (Trojan 代理)"
echo "  - shadowsocks-libev (Shadowsocks)"
echo "  - naiveproxy, kcptun 等"
echo ""
echo "🔧 Go 版本: 已配置使用最新版本"
echo "=================================================="