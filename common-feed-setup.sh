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

    # Clean legacy/conflicting SmartDNS entries and use official pymumu/smartdns latest source
    rm -rf feeds/luci/applications/luci-app-smartdns
    rm -rf package/feeds/luci/luci-app-smartdns
    rm -rf feeds/packages/net/smartdns
    rm -rf package/feeds/packages/smartdns
    rm -rf feeds/*/luci-app-smartdns feeds/*/smartdns
    rm -rf package/feeds/*/luci-app-smartdns package/feeds/*/smartdns
    rm -rf package/smartdns package/luci-app-smartdns
    git clone --depth 1 https://github.com/pymumu/openwrt-smartdns.git package/smartdns
    git clone --depth 1 https://github.com/pymumu/luci-app-smartdns.git package/luci-app-smartdns

    # Dynamically obtain latest pymumu/smartdns release tag (e.g. Release48.4 -> 48.4) and its commit
    smartdns_tag="$(git ls-remote --tags --refs https://github.com/pymumu/smartdns.git 2>/dev/null | awk -F'/' '{print $3}' | grep -E '^Release[0-9]+(\.[0-9]+)*$' | sort -V | tail -n 1 || true)"
    smartdns_ver="${smartdns_tag#Release}"
    [ -n "${smartdns_ver}" ] || smartdns_ver="48.4"

    smartdns_commit=""
    if [ -n "${smartdns_tag}" ]; then
        smartdns_commit="$(git ls-remote --tags --refs https://github.com/pymumu/smartdns.git "refs/tags/${smartdns_tag}" 2>/dev/null | awk '{print $1}' || true)"
    fi
    if [ -z "${smartdns_commit}" ]; then
        smartdns_commit="$(git ls-remote https://github.com/pymumu/smartdns.git HEAD 2>/dev/null | awk '{print $1}' || true)"
    fi
    [ -n "${smartdns_commit}" ] || smartdns_commit="21c940edc65520849ba03544c5cf8d9cf326e680"

    smartdns_pkg_ver="1.$(date +%Y).${smartdns_ver}"

    sed -i 's|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/pymumu/smartdns.git|g' package/smartdns/Makefile
    sed -i "s|^PKG_VERSION:=.*|PKG_VERSION:=${smartdns_pkg_ver}|g" package/smartdns/Makefile
    sed -i "s|^PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=${smartdns_commit}|g" package/smartdns/Makefile
    sed -i 's/PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/g' package/smartdns/Makefile

    # Sync luci-app-smartdns package version with smartdns
    sed -i "s|^PKG_VERSION:=.*|PKG_VERSION:=${smartdns_pkg_ver}|g" package/luci-app-smartdns/Makefile

    # Clean default MosDNS and pull sbwml v5 branch with geodata
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

    # Use stable golang 26.x
    rm -rf feeds/packages/lang/golang
    rm -rf package/feeds/packages/golang
    git clone --depth 1 -b 26.x https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

    echo "Feed cleanup and pinning completed."
}
