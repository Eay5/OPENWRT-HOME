#!/bin/bash

add_or_replace_feed() {
    local name="$1"
    local url="$2"

    sed -i "\|^src-git ${name} |d" feeds.conf.default
    sed -i "1i src-git ${name} ${url}" feeds.conf.default
}

setup_common_feeds() {
    echo "Adding custom feeds..."

    # Clean old helloworld feed and conflicting passwall feeds
    sed -i '\|^src-git helloworld |d' feeds.conf.default 2>/dev/null || true
    sed -i '\|^src-git passwall |d' feeds.conf.default 2>/dev/null || true

    echo "Updated feeds.conf.default:"
    cat feeds.conf.default

    ./scripts/feeds update -a

    echo "Pinning third-party package sources..."

    # 移除 openwrt feeds 自带的过时核心库与旧版 luci-app-passwall，按官方公告由 passwall 官方仓库接管
    rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,v2ray-plugin,xray-plugin,geoview,shadow-tls} 2>/dev/null || true
    rm -rf feeds/luci/applications/luci-app-passwall package/feeds/luci/luci-app-passwall 2>/dev/null || true
    rm -rf package/passwall-packages package/passwall-luci
    git clone --depth 1 -b main https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/passwall-packages
    git clone --depth 1 -b main https://github.com/Openwrt-Passwall/openwrt-passwall.git package/passwall-luci

    # 移除 passwall-packages 中与独立源码仓库重叠的重复包，防止编译时报 duplicate package 冲突
    rm -rf package/passwall-packages/smartdns package/passwall-packages/luci-app-smartdns package/passwall-packages/mosdns package/passwall-packages/luci-app-mosdns package/passwall-packages/v2ray-geodata package/passwall-packages/v2ray-rules-dat 2>/dev/null || true

    # Clean conflicting feeds and pull official pymumu/smartdns latest source
    rm -rf feeds/luci/applications/luci-app-smartdns package/feeds/luci/luci-app-smartdns
    rm -rf feeds/packages/net/smartdns package/feeds/packages/smartdns
    rm -rf feeds/*/luci-app-smartdns feeds/*/smartdns package/feeds/*/luci-app-smartdns package/feeds/*/smartdns
    rm -rf package/smartdns package/luci-app-smartdns
    git clone --depth 1 https://github.com/pymumu/openwrt-smartdns.git package/smartdns
    git clone --depth 1 https://github.com/pymumu/luci-app-smartdns.git package/luci-app-smartdns

    # 动态获取 upstream pymumu/smartdns 最新 master commit 与最新 release 标签，保持实时编译最新版本
    local smartdns_commit=""
    local smartdns_tag=""
    local smartdns_ver=""

    smartdns_commit=$(git ls-remote https://github.com/pymumu/smartdns.git refs/heads/master 2>/dev/null | cut -f1 || true)
    smartdns_tag=$(git ls-remote --tags --refs https://github.com/pymumu/smartdns.git 2>/dev/null | grep -oE 'refs/tags/Release[0-9.]+$' | sed 's#refs/tags/##' | sort -V | tail -n 1 || true)

    if [ -n "${smartdns_tag}" ]; then
        smartdns_ver="1.$(date +%Y).${smartdns_tag#Release}"
    fi

    if [ -n "${smartdns_commit}" ]; then
        sed -i "s/^PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=${smartdns_commit}/g" package/smartdns/Makefile
        [ -n "${smartdns_ver}" ] && sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${smartdns_ver}/g" package/smartdns/Makefile
        echo "SmartDNS tracking upstream master: Commit=${smartdns_commit}, Version=${smartdns_ver:-latest}"
    fi

    sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/g' package/smartdns/Makefile 2>/dev/null || true
    sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/g' package/smartdns/Makefile 2>/dev/null || true
    sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/g' package/luci-app-smartdns/Makefile 2>/dev/null || true
    sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/g' package/luci-app-smartdns/Makefile 2>/dev/null || true

    # Clean conflicting MosDNS and pull sbwml v5 branch with geodata
    rm -rf feeds/luci/applications/luci-app-mosdns package/feeds/luci/luci-app-mosdns
    rm -rf feeds/*/luci-app-mosdns package/feeds/*/luci-app-mosdns
    rm -rf feeds/*/mosdns package/feeds/*/mosdns package/mosdns package/v2ray-geodata
    git clone --depth 1 -b v5 https://github.com/sbwml/luci-app-mosdns package/mosdns
    git clone --depth 1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

    # 动态获取 upstream sbwml/packages_lang_golang 最新分支，保持实时编译最新版本
    local golang_branch=""
    golang_branch=$(git ls-remote --heads https://github.com/sbwml/packages_lang_golang.git 2>/dev/null | grep -o 'refs/heads/[0-9]\+\.x' | sed 's#refs/heads/##' | sort -V | tail -n 1 || true)
    golang_branch="${golang_branch:-27.x}"

    rm -rf feeds/packages/lang/golang
    rm -rf package/feeds/packages/golang
    git clone --depth 1 -b "${golang_branch}" https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang
    echo "Golang tracking upstream latest branch: ${golang_branch}"

    # 针对 Go 27+ 适配补丁：关闭未定稿的 jsonv2 等实验性特性，防止 sing-box / 第三方库发生符号冲突
    if [ -f feeds/packages/lang/golang/golang-build.sh ]; then
        sed -i '1a export GOEXPERIMENT=none' feeds/packages/lang/golang/golang-build.sh 2>/dev/null || true
    fi
    for mk in feeds/packages/lang/golang/golang-package.mk feeds/packages/lang/golang/golang-values.mk; do
        if [ -f "$mk" ]; then
            sed -i 's/GOENV=off/GOENV=off GOEXPERIMENT=none/g' "$mk" 2>/dev/null || true
        fi
    done

    # 动态获取 upstream XTLS/Xray-core 最新 Release 版本，保持实时编译最新核心
    local xray_tag=""
    xray_tag=$(git ls-remote --tags --refs https://github.com/XTLS/Xray-core.git 2>/dev/null | grep -oE 'refs/tags/v[0-9.]+$' | sed 's#refs/tags/v##' | sort -V | tail -n 1 || true)
    if [ -n "${xray_tag}" ]; then
        for xray_mk in package/passwall-packages/xray-core/Makefile feeds/packages/net/xray-core/Makefile package/xray-core/Makefile; do
            if [ -f "$xray_mk" ]; then
                sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${xray_tag}/g" "$xray_mk"
                sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/g' "$xray_mk"
            fi
        done
        echo "Xray-core tracking upstream latest release: v${xray_tag}"
    fi

    # 动态获取 upstream SagerNet/sing-box 最新 Release 版本，保持实时编译最新核心
    local singbox_tag=""
    singbox_tag=$(git ls-remote --tags --refs https://github.com/SagerNet/sing-box.git 2>/dev/null | grep -oE 'refs/tags/v[0-9.]+$' | sed 's#refs/tags/v##' | sort -V | tail -n 1 || true)
    if [ -n "${singbox_tag}" ]; then
        for singbox_mk in package/passwall-packages/sing-box/Makefile feeds/packages/net/sing-box/Makefile package/sing-box/Makefile; do
            if [ -f "$singbox_mk" ]; then
                sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${singbox_tag}/g" "$singbox_mk"
                sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/g' "$singbox_mk"
                sed -i '/GO_PKG_BUILD_VARS/ s/$/ GOEXPERIMENT=none/' "$singbox_mk" 2>/dev/null || true
            fi
        done
        echo "Sing-box tracking upstream latest release: v${singbox_tag}"
    fi

    # 动态获取 Loyalsoldier/v2ray-rules-dat 实时最新规则库
    sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/g' package/v2ray-geodata/Makefile 2>/dev/null || true
    echo "GeoData rules library tracking upstream latest daily release"

    echo "Feed cleanup and pinning completed."
}
