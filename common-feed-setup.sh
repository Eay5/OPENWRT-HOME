#!/bin/bash

add_or_replace_feed() {
    local name="$1"
    local url="$2"

    sed -i "\|^src-git ${name} |d" feeds.conf.default
    sed -i "1i src-git ${name} ${url}" feeds.conf.default
}

setup_common_feeds() {
    echo "Adding custom feeds..."

    sed -i '\|^src-git small |d' feeds.conf.default
    sed -i '\|^src-git smpackage |d' feeds.conf.default
    sed -i '\|https://github.com/kenzok8/small$|d' feeds.conf.default
    sed -i '\|https://github.com/kenzok8/small-package$|d' feeds.conf.default

    add_or_replace_feed "kenzo" "https://github.com/kenzok8/openwrt-packages"
    add_or_replace_feed "helloworld" "https://github.com/fw876/helloworld"

    echo "Updated feeds.conf.default:"
    cat feeds.conf.default

    ./scripts/feeds update -a

    echo "Pinning third-party package sources..."

    rm -rf feeds/luci/applications/luci-app-smartdns
    rm -rf package/feeds/luci/luci-app-smartdns
    rm -rf feeds/packages/net/smartdns
    rm -rf package/feeds/packages/smartdns

    rm -rf feeds/kenzo/luci-app-ssr-plus
    rm -rf package/feeds/kenzo/luci-app-ssr-plus
    rm -rf feeds/kenzo/{chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray*,xray*,sing*,geoview,shadow-tls}
    rm -rf package/feeds/kenzo/{chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray*,xray*,sing*,geoview,shadow-tls}

    rm -rf feeds/packages/net/{adguardhome,alist,mosdns,xray*,v2ray*,sing*,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
    rm -rf package/feeds/packages/{adguardhome,alist,mosdns,xray*,v2ray*,sing*,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
    rm -rf feeds/packages/utils/v2dat
    rm -rf package/feeds/packages/v2dat

    rm -rf feeds/luci/applications/luci-app-alist
    rm -rf package/feeds/luci/luci-app-alist
    rm -rf feeds/packages/net/alist
    rm -rf package/feeds/packages/alist

    rm -rf feeds/luci/applications/luci-app-mosdns
    rm -rf package/feeds/luci/luci-app-mosdns
    rm -rf feeds/*/luci-app-mosdns
    rm -rf package/feeds/*/luci-app-mosdns
    rm -rf feeds/*/mosdns
    rm -rf package/feeds/*/mosdns
    rm -rf package/mosdns
    rm -rf package/v2ray-geodata
    git clone --depth 1 -b v5 https://github.com/sbwml/luci-app-mosdns package/mosdns
    git clone --depth 1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

    rm -rf feeds/packages/lang/golang
    rm -rf package/feeds/packages/golang
    git clone --depth 1 -b 25.x https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

    rm -rf feeds/luci/applications/luci-app-fchomo
    rm -rf feeds/luci/applications/luci-app-bypass
    rm -rf package/feeds/luci/luci-app-fchomo
    rm -rf package/feeds/luci/luci-app-bypass
    rm -rf feeds/kenzo/luci-app-fchomo
    rm -rf feeds/kenzo/luci-app-bypass
    rm -rf package/feeds/kenzo/luci-app-fchomo
    rm -rf package/feeds/kenzo/luci-app-bypass

    echo "Feed cleanup completed."
}
