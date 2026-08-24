#!/bin/bash

add_or_replace_feed() {
    local name="$1"
    local url="$2"

    sed -i "\|^src-git ${name} |d" feeds.conf.default
    sed -i "1i src-git ${name} ${url}" feeds.conf.default
}

setup_common_feeds() {
    echo "Adding custom feeds..."

    # Use helloworld feed for SSR-Plus and proxy runtimes
    add_or_replace_feed "helloworld" "https://github.com/fw876/helloworld"

    echo "Updated feeds.conf.default:"
    cat feeds.conf.default

    ./scripts/feeds update -a

    echo "Pinning third-party package sources..."

    # Clean conflicting feeds and pull official pymumu/smartdns latest source
    rm -rf feeds/luci/applications/luci-app-smartdns package/feeds/luci/luci-app-smartdns
    rm -rf feeds/packages/net/smartdns package/feeds/packages/smartdns
    rm -rf feeds/*/luci-app-smartdns feeds/*/smartdns package/feeds/*/luci-app-smartdns package/feeds/*/smartdns
    rm -rf package/smartdns package/luci-app-smartdns
    git clone --depth 1 https://github.com/pymumu/openwrt-smartdns.git package/smartdns
    git clone --depth 1 https://github.com/pymumu/luci-app-smartdns.git package/luci-app-smartdns
    sed -i 's/PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/g' package/smartdns/Makefile 2>/dev/null || true
    sed -i 's/PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/g' package/luci-app-smartdns/Makefile 2>/dev/null || true

    # Clean conflicting MosDNS and pull sbwml v5 branch with geodata
    rm -rf feeds/luci/applications/luci-app-mosdns package/feeds/luci/luci-app-mosdns
    rm -rf feeds/*/luci-app-mosdns package/feeds/*/luci-app-mosdns
    rm -rf feeds/*/mosdns package/feeds/*/mosdns package/mosdns package/v2ray-geodata
    git clone --depth 1 -b v5 https://github.com/sbwml/luci-app-mosdns package/mosdns
    git clone --depth 1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

    # Use stable golang 26.x
    rm -rf feeds/packages/lang/golang
    rm -rf package/feeds/packages/golang
    git clone --depth 1 -b 26.x https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

    echo "Feed cleanup and pinning completed."
}
