#!/bin/bash

setup_common_feeds() {
    echo "Adding custom feeds..."

    # Clean old helloworld, passwall, mosdns feeds if present
    sed -i '\|^src-git helloworld |d' feeds.conf.default 2>/dev/null || true
    sed -i '\|^src-git passwall |d' feeds.conf.default 2>/dev/null || true
    sed -i '\|^src-git mosdns |d' feeds.conf.default 2>/dev/null || true

    echo "Updated feeds.conf.default:"
    cat feeds.conf.default

    ./scripts/feeds update -a

    echo "Pinning third-party package sources..."

    # 彻底清理旧版 passwall 与 mosdns 残留，避免包名和依赖冲突
    rm -rf feeds/luci/applications/luci-app-passwall package/feeds/luci/luci-app-passwall 2>/dev/null || true
    rm -rf feeds/packages/net/{xray-core,chinadns-ng,dns2socks,ipt2socks,microsocks,naiveproxy,shadow-tls,mosdns} 2>/dev/null || true
    rm -rf feeds/luci/applications/luci-app-mosdns package/feeds/luci/luci-app-mosdns 2>/dev/null || true
    rm -rf feeds/*/luci-app-mosdns feeds/*/*/luci-app-mosdns package/feeds/*/luci-app-mosdns package/feeds/*/*/luci-app-mosdns 2>/dev/null || true
    rm -rf feeds/*/mosdns feeds/*/*/mosdns package/feeds/*/mosdns package/feeds/*/*/mosdns 2>/dev/null || true
    rm -rf package/passwall-packages package/passwall-luci package/mosdns package/v2ray-geodata 2>/dev/null || true

    # 拉取 ImmortalWrt 官方最新 HomeProxy 源码
    rm -rf feeds/luci/applications/luci-app-homeproxy package/feeds/luci/luci-app-homeproxy package/homeproxy 2>/dev/null || true
    git clone --depth 1 https://github.com/immortalwrt/homeproxy.git package/homeproxy

    # Clean conflicting feeds and pull official pymumu/smartdns latest source
    rm -rf feeds/luci/applications/luci-app-smartdns package/feeds/luci/luci-app-smartdns 2>/dev/null || true
    rm -rf feeds/packages/net/smartdns package/feeds/packages/smartdns 2>/dev/null || true
    rm -rf feeds/*/luci-app-smartdns feeds/*/smartdns feeds/*/*/luci-app-smartdns feeds/*/*/smartdns package/feeds/*/luci-app-smartdns package/feeds/*/smartdns package/feeds/*/*/luci-app-smartdns package/feeds/*/*/smartdns 2>/dev/null || true
    rm -rf package/smartdns package/luci-app-smartdns 2>/dev/null || true
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

    # 动态获取 upstream SagerNet/sing-box 最新 Release 版本，保持实时编译 HomeProxy 核心
    local singbox_tag=""
    singbox_tag=$(git ls-remote --tags --refs https://github.com/SagerNet/sing-box.git 2>/dev/null | grep -oE 'refs/tags/v[0-9.]+$' | sed 's#refs/tags/v##' | sort -V | tail -n 1 || true)
    if [ -n "${singbox_tag}" ]; then
        for singbox_mk in feeds/packages/net/sing-box/Makefile package/feeds/packages/sing-box/Makefile package/sing-box/Makefile; do
            if [ -f "$singbox_mk" ]; then
                sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${singbox_tag}/g" "$singbox_mk"
                sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/g' "$singbox_mk"
                sed -i '/GO_PKG_BUILD_VARS/ s/$/ GOEXPERIMENT=none/' "$singbox_mk" 2>/dev/null || true
            fi
        done
        echo "Sing-box tracking upstream latest release: v${singbox_tag}"
    fi

    echo "Feed cleanup and pinning completed."
}
