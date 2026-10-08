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
    rm -rf feeds/luci/applications/luci-app-mosdns package/feeds/luci/luci-app-mosdns 2>/dev/null || true
    rm -rf feeds/*/luci-app-mosdns feeds/*/*/luci-app-mosdns package/feeds/*/luci-app-mosdns package/feeds/*/*/luci-app-mosdns 2>/dev/null || true
    rm -rf feeds/*/mosdns feeds/*/*/mosdns package/feeds/*/mosdns package/feeds/*/*/mosdns 2>/dev/null || true
    rm -rf package/passwall-packages package/passwall-luci package/mosdns package/v2ray-geodata 2>/dev/null || true

    # 确保 Realtek r8126 (5G) 网卡驱动包存在 (若官方源码树未收录则拉取 sbwml 独立包兜底)
    if [ ! -d "package/kernel/r8126" ] && [ ! -d "package/emortal/r8126" ] && [ ! -d "package/network/utils/r8126" ]; then
        echo "Official r8126 driver not found in tree, pulling sbwml/package_kernel_r8126..."
        rm -rf package/kernel/r8126 2>/dev/null || true
        git clone --depth 1 https://github.com/sbwml/package_kernel_r8126.git package/kernel/r8126
        echo "Pulled r8126 5G driver from sbwml/package_kernel_r8126."
    else
        echo "Official r8126 driver detected in source tree."
    fi

    # 拉取 ImmortalWrt 官方最新 HomeProxy 源码
    rm -rf feeds/luci/applications/luci-app-homeproxy package/feeds/luci/luci-app-homeproxy package/homeproxy 2>/dev/null || true
    git clone --depth 1 https://github.com/immortalwrt/homeproxy.git package/homeproxy

    # 修复 HomeProxy Makefile 依赖与路径 (补齐缺失的 ucode-mod-math 依赖，并保证 PKG_NAME 结构完整)
    if [ -f package/homeproxy/Makefile ]; then
        sed -i 's|include \.\./\.\./luci\.mk|include $(TOPDIR)/feeds/luci/luci.mk|g' package/homeproxy/Makefile 2>/dev/null || true
        if ! grep -q 'ucode-mod-math' package/homeproxy/Makefile; then
            sed -i 's/+ucode-mod-digest.*$/+ucode-mod-digest \\\n\t+ucode-mod-math/' package/homeproxy/Makefile 2>/dev/null || true
        fi
    fi

    # 适配最新版 sing-box (>=1.13.0)：移除已废弃的旧版 inbounds 嗅探字段，彻底解决新版 sing-box FATAL decode config 报错
    find package/homeproxy -name "generate_client.uc" -exec sed -i '/sniff_override_destination/d' {} + 2>/dev/null || true
    find package/homeproxy -name "generate_client.uc" -exec sed -i '/\bsniff:/d' {} + 2>/dev/null || true

    # Clean conflicting feeds and pull SmartDNS package source
    rm -rf feeds/luci/applications/luci-app-smartdns package/feeds/luci/luci-app-smartdns 2>/dev/null || true
    rm -rf feeds/packages/net/smartdns package/feeds/packages/smartdns 2>/dev/null || true
    rm -rf feeds/*/luci-app-smartdns feeds/*/smartdns feeds/*/*/luci-app-smartdns feeds/*/*/smartdns package/feeds/*/luci-app-smartdns package/feeds/*/smartdns package/feeds/*/*/luci-app-smartdns package/feeds/*/*/smartdns 2>/dev/null || true
    rm -rf package/smartdns package/luci-app-smartdns 2>/dev/null || true
    git clone --depth 1 https://github.com/pymumu/openwrt-smartdns.git package/smartdns
    git clone --depth 1 https://github.com/pymumu/luci-app-smartdns.git package/luci-app-smartdns

    # 切换上游为社区活跃增强分支 PikuZheng/smartdns (解决 HTTP/2 泄漏、musl 内存碎片化、高并发崩溃及 OpenSSL 3.5.8 适配)
    sed -i 's#https://www.github.com/pymumu/smartdns.git#https://github.com/PikuZheng/smartdns.git#g' package/smartdns/Makefile 2>/dev/null || true
    sed -i 's#https://github.com/pymumu/smartdns.git#https://github.com/PikuZheng/smartdns.git#g' package/smartdns/Makefile 2>/dev/null || true

    # 动态获取 upstream PikuZheng/smartdns 最新稳定 release 标签与 master commit
    local smartdns_commit=""
    local smartdns_tag=""
    local smartdns_ver=""

    smartdns_tag=$(git ls-remote --tags --refs https://github.com/PikuZheng/smartdns.git 2>/dev/null \
        | grep -v 'canary' \
        | grep -oE 'refs/tags/1\.[0-9]+\.v[0-9.]+' \
        | sed 's#refs/tags/##' \
        | sort -V \
        | tail -n 1 || true)

    smartdns_ver="${smartdns_tag:-1.2026.v48.4.2}"

    # 优先匹配对应标签的 commit hash，若未匹配则取 master 分支最新 commit
    if [ -n "${smartdns_tag}" ]; then
        smartdns_commit=$(git ls-remote --tags https://github.com/PikuZheng/smartdns.git "refs/tags/${smartdns_tag}" 2>/dev/null | cut -f1 | head -n 1 || true)
        [ -z "${smartdns_commit}" ] && smartdns_commit=$(git ls-remote --tags https://github.com/PikuZheng/smartdns.git "refs/tags/${smartdns_tag}_with_ui" 2>/dev/null | cut -f1 | head -n 1 || true)
    fi

    if [ -z "${smartdns_commit}" ]; then
        smartdns_commit=$(git ls-remote https://github.com/PikuZheng/smartdns.git refs/heads/master 2>/dev/null | cut -f1 || true)
    fi

    # 兜底已知最稳定发行版 commit (1.2026.v48.4.2)
    smartdns_commit="${smartdns_commit:-395ea7e05619ed030c4898467d56e59445ffb84e}"

    sed -i "s/^PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=${smartdns_commit}/g" package/smartdns/Makefile
    sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${smartdns_ver}/g" package/smartdns/Makefile
    sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${smartdns_ver}/g" package/luci-app-smartdns/Makefile 2>/dev/null || true
    sed -i "s/^PKG_RELEASE:=.*/PKG_RELEASE:=1/g" package/luci-app-smartdns/Makefile 2>/dev/null || true
    echo "SmartDNS tracking PikuZheng upstream: Version=${smartdns_ver}, Commit=${smartdns_commit}"

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

    # 动态获取 upstream SagerNet/sing-box 最新正式稳定版本 (严格过滤三段式纯数字标签，100% 排除 alpha/beta/rc 测试版)
    local singbox_tag=""
    singbox_tag=$(git ls-remote --tags --refs https://github.com/SagerNet/sing-box.git 2>/dev/null \
        | grep -oE 'refs/tags/v[0-9]+\.[0-9]+(\.[0-9]+)?$' \
        | sed 's#refs/tags/v##' \
        | sort -V \
        | tail -n 1 || true)

    # 兜底安全稳定版本
    singbox_tag="${singbox_tag:-1.13.19}"

    if [ -n "${singbox_tag}" ]; then
        for singbox_mk in feeds/packages/net/sing-box/Makefile package/feeds/packages/sing-box/Makefile package/sing-box/Makefile; do
            if [ -f "$singbox_mk" ]; then
                sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${singbox_tag}/g" "$singbox_mk"
                sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/g' "$singbox_mk"
                sed -i '/GO_PKG_BUILD_VARS/ s/$/ GOEXPERIMENT=none/' "$singbox_mk" 2>/dev/null || true
            fi
        done
        echo "Sing-box tracking upstream latest STABLE release: v${singbox_tag}"
    fi

    # 动态获取 upstream gdy666/luci-app-lucky 最新官方源码与稳定二进制 Release 版本
    rm -rf feeds/luci/applications/luci-app-lucky package/feeds/luci/luci-app-lucky 2>/dev/null || true
    rm -rf feeds/*/luci-app-lucky package/feeds/*/luci-app-lucky 2>/dev/null || true
    rm -rf package/lucky 2>/dev/null || true
    git clone --depth 1 https://github.com/gdy666/luci-app-lucky.git package/lucky

    local lucky_tag=""
    lucky_tag=$(git ls-remote --tags --refs https://github.com/gdy666/lucky.git 2>/dev/null \
        | grep -oE 'refs/tags/v[0-9.]+$' \
        | sed 's#refs/tags/v##' \
        | sort -V \
        | tail -n 1 || true)

    if [ -n "${lucky_tag}" ]; then
        if [ -f package/lucky/lucky/Makefile ]; then
            sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${lucky_tag}/g" package/lucky/lucky/Makefile
            echo "Lucky tracking upstream latest release: v${lucky_tag}"
        fi
    fi

    echo "Feed cleanup and pinning completed."
}
