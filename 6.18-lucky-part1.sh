#!/bin/bash
# ==============================================================================
# 6.18-lucky 专属独立 Part 1 编译脚本（完全独立，不共用 common-feed-setup.sh）
# ==============================================================================
set -euo pipefail

safe_git_clone() {
    local repo_url="$1"
    local dest_dir="$2"
    local branch="${3:-}"
    local attempt

    for attempt in 1 2 3; do
        rm -rf "${dest_dir}" 2>/dev/null || true
        if [ -n "${branch}" ]; then
            if git clone --depth 1 -b "${branch}" "${repo_url}" "${dest_dir}"; then
                return 0
            fi
        else
            if git clone --depth 1 "${repo_url}" "${dest_dir}"; then
                return 0
            fi
        fi
        echo "警告: 克隆 ${repo_url} 失败 (第 ${attempt}/3 次)，3 秒后重试..."
        sleep 3
    done

    echo "错误: 无法克隆 ${repo_url} 到 ${dest_dir}"
    return 1
}

setup_lucky_argon_theme() {
    echo "Pinning luci-theme-argon to upstream latest release (LUCKY standalone)..."
    rm -rf feeds/luci/themes/luci-theme-argon package/feeds/luci/luci-theme-argon 2>/dev/null || true
    rm -rf package/luci-app-argon-config feeds/luci/applications/luci-app-argon-config package/feeds/luci/luci-app-argon-config 2>/dev/null || true
    rm -rf package/luci-theme-argon 2>/dev/null || true

    safe_git_clone "https://github.com/jerrykuku/luci-theme-argon.git" "package/luci-theme-argon"

    local argon_ver=""
    if [ -f "package/luci-theme-argon/Makefile" ]; then
        argon_ver=$(sed -n 's/^PKG_VERSION:=[[:space:]]*//p' package/luci-theme-argon/Makefile 2>/dev/null | tr -d '\r' | head -n 1)
    fi

    local argon_remote_tag=""
    argon_remote_tag=$(git ls-remote --tags --refs https://github.com/jerrykuku/luci-theme-argon.git 2>/dev/null \
        | grep -oE 'refs/tags/v?[0-9.]+$' \
        | sed 's#refs/tags/##' \
        | sort -V \
        | tail -n 1 || true)

    if [ -n "${argon_remote_tag}" ]; then
        local remote_clean="${argon_remote_tag#v}"
        if [ -z "${argon_ver}" ] || [ "$(printf '%s\n%s' "${argon_ver}" "${remote_clean}" | sort -V | tail -n 1)" = "${remote_clean}" ]; then
            argon_ver="${remote_clean}"
        fi
    fi

    argon_ver="${argon_ver:-3.1.1}"
    argon_ver="${argon_ver#v}"

    if [ -f "package/luci-theme-argon/Makefile" ]; then
        sed -i 's|include \.\./\.\./luci\.mk|include $(TOPDIR)/feeds/luci/luci.mk|g' package/luci-theme-argon/Makefile 2>/dev/null || true
        sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${argon_ver}/g" package/luci-theme-argon/Makefile
        sed -i "s/^PKG_RELEASE:=.*/PKG_RELEASE:=1/g" package/luci-theme-argon/Makefile 2>/dev/null || true
        sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/g' package/luci-theme-argon/Makefile 2>/dev/null || true
        sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/g' package/luci-theme-argon/Makefile 2>/dev/null || true
    fi

    find package/luci-theme-argon -type f \( -name "footer*.ut" -o -name "footer*.htm" \) -exec sed -i -E \
        -e "s/\\{# vPKG_VERSION #\\}/v${argon_ver}/g" \
        -e "s/\\{# PKG_VERSION #\\}/${argon_ver}/g" \
        -e "s/v3\.0\.0/v${argon_ver}/g" {} + 2>/dev/null || true

    echo "LUCKY luci-theme-argon synced to v${argon_ver}"
}

setup_lucky_feeds() {
    echo "Setting up standalone feeds for 6.18 LUCKY..."

    # 1. 清理 feeds.conf.default 中与 Lucky 无关的第三方源，并更新官方 feeds 索引
    sed -i '/helloworld/d;/passwall/d;/mosdns/d;/openwrt_honk/d' feeds.conf.default 2>/dev/null || true
    echo "Updating official feeds for 6.18 LUCKY..."
    ./scripts/feeds update -a

    # 1.1 清理与 Lucky 无关的代理残留（必须在 feeds update -a 之后执行，彻底清除官方源中的无关包）
    rm -rf package/homeproxy feeds/luci/applications/luci-app-homeproxy package/feeds/luci/luci-app-homeproxy 2>/dev/null || true
    rm -rf package/smartdns package/luci-app-smartdns feeds/luci/applications/luci-app-smartdns package/feeds/luci/luci-app-smartdns 2>/dev/null || true
    rm -rf feeds/packages/net/sing-box package/feeds/packages/sing-box 2>/dev/null || true
    rm -rf package/openwrt-honk package/honk 2>/dev/null || true

    # 2. 修复 firewall4 FullCone NAT 补丁上游兼容冲突
    local fw4_patch_dir="package/network/config/firewall4/patches"
    local fw4_patch="${fw4_patch_dir}/001-firewall4-add-support-for-fullcone-nat.patch"
    if [ -d "$fw4_patch_dir" ]; then
        if [ -f "${GITHUB_WORKSPACE:-}/patches/001-firewall4-add-support-for-fullcone-nat.patch" ]; then
            cp -f "${GITHUB_WORKSPACE}/patches/001-firewall4-add-support-for-fullcone-nat.patch" "$fw4_patch"
            echo "Overwrote firewall4 fullcone patch using validated repository patch."
        elif command -v curl >/dev/null 2>&1; then
            curl -fsSL --connect-timeout 10 -m 30 "https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/package/network/config/firewall4/patches/001-firewall4-add-support-for-fullcone-nat.patch" -o "$fw4_patch" 2>/dev/null || true
        fi
        if [ -f "$fw4_patch" ]; then
            sed -i '/# Uncomment this line to disable ipv6 rules/,/#\toption disable_ipv6\t1/d' "$fw4_patch" 2>/dev/null || true
            sed -i 's/@@ -5,6 +5,10 @@/@@ -3,6 +3,10 @@/g' "$fw4_patch" 2>/dev/null || true
            sed -i 's/zone\.dflags\.helper = true;/zone.dflags.helper = false;/g' "$fw4_patch" 2>/dev/null || true
        fi
    fi

    # 3. 确保 Realtek r8126 (5G) 网卡驱动可用
    if [ ! -d "package/kernel/r8126" ] && [ ! -d "package/emortal/r8126" ] && [ ! -d "package/network/utils/r8126" ]; then
        rm -rf package/kernel/r8126 2>/dev/null || true
        safe_git_clone "https://github.com/sbwml/package_kernel_r8126.git" "package/kernel/r8126"
    fi
    for r_mk in package/kernel/r8126/Makefile package/emortal/r8126/Makefile package/kernel/r8125/Makefile; do
        if [ -f "$r_mk" ]; then
            sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/g' "$r_mk" 2>/dev/null || true
            sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/g' "$r_mk" 2>/dev/null || true
        fi
    done

    # 4. 动态拉取最新 Golang 分支并启用 GOAMD64=v2 指令集加速
    local golang_branch=""
    golang_branch=$(git ls-remote --heads https://github.com/sbwml/packages_lang_golang.git 2>/dev/null | grep -o 'refs/heads/[0-9]\+\.x' | sed 's#refs/heads/##' | sort -V | tail -n 1 || true)
    golang_branch="${golang_branch:-27.x}"
    rm -rf feeds/packages/lang/golang package/feeds/packages/golang
    safe_git_clone "https://github.com/sbwml/packages_lang_golang" "feeds/packages/lang/golang" "${golang_branch}"
    if [ -f feeds/packages/lang/golang/golang-build.sh ]; then
        sed -i '1a export GOEXPERIMENT=none\nexport GOAMD64=v2' feeds/packages/lang/golang/golang-build.sh 2>/dev/null || true
    fi
    for mk in feeds/packages/lang/golang/golang-package.mk feeds/packages/lang/golang/golang-values.mk; do
        if [ -f "$mk" ]; then
            sed -i 's/GOENV=off/GOENV=off GOEXPERIMENT=none GOAMD64=v2/g' "$mk" 2>/dev/null || true
            sed -i 's/GOAMD64:=v1/GOAMD64:=v2/g' "$mk" 2>/dev/null || true
        fi
    done

    # 5. 动态拉取 gdy666/luci-app-lucky 最新官方源码并同步最新正式版 Tag
    rm -rf feeds/luci/applications/luci-app-lucky package/feeds/luci/luci-app-lucky 2>/dev/null || true
    rm -rf feeds/*/luci-app-lucky package/feeds/*/luci-app-lucky package/lucky 2>/dev/null || true
    safe_git_clone "https://github.com/gdy666/luci-app-lucky.git" "package/lucky"

    local lucky_tag=""
    lucky_tag=$(git ls-remote --tags --refs https://github.com/gdy666/lucky.git 2>/dev/null \
        | grep -oE 'refs/tags/v[0-9.]+$' \
        | sed 's#refs/tags/v##' \
        | sort -V \
        | tail -n 1 || true)

    if [ -n "${lucky_tag}" ]; then
        for lucky_mk in package/lucky/lucky/Makefile package/lucky/luci-app-lucky/Makefile package/lucky/Makefile; do
            if [ -f "$lucky_mk" ]; then
                sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${lucky_tag}/g" "$lucky_mk" 2>/dev/null || true
                sed -i "s/^PKG_RELEASE:=.*/PKG_RELEASE:=1/g" "$lucky_mk" 2>/dev/null || true
                sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/g' "$lucky_mk" 2>/dev/null || true
                sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/g' "$lucky_mk" 2>/dev/null || true
            fi
        done
        echo "Lucky tracking upstream latest release: v${lucky_tag}"
    fi

    # 6. 升级 Dnsmasq 至官方最新正式版 (2.93+)
    local dnsmasq_tag=""
    dnsmasq_tag=$(curl -sL --connect-timeout 5 --max-time 10 https://thekelleys.org.uk/dnsmasq/ 2>/dev/null \
        | grep -oE 'LATEST_IS_[0-9.]+' \
        | head -n 1 \
        | sed 's/LATEST_IS_//' || true)
    local dnsmasq_ver="${dnsmasq_tag:-2.93}"
    local dnsmasq_hash="0c00d4e5c97c8306e5fb932b348b34269c9c29a0e7df0e8e82958b407092bc19"
    local dnsmasq_mk="package/network/services/dnsmasq/Makefile"
    if [ -f "${dnsmasq_mk}" ]; then
        rm -rf package/network/services/dnsmasq/patches 2>/dev/null || true
        if grep -q "^PKG_UPSTREAM_VERSION:=" "${dnsmasq_mk}"; then
            sed -i "s/^PKG_UPSTREAM_VERSION:=.*/PKG_UPSTREAM_VERSION:=${dnsmasq_ver}/g" "${dnsmasq_mk}"
        else
            sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${dnsmasq_ver}/g" "${dnsmasq_mk}"
        fi
        if [ "${dnsmasq_ver}" = "2.93" ]; then
            sed -i "s/^PKG_HASH:=.*/PKG_HASH:=${dnsmasq_hash}/g" "${dnsmasq_mk}"
        else
            sed -i "s/^PKG_HASH:=.*/PKG_HASH:=skip/g" "${dnsmasq_mk}"
        fi
        sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/g' "${dnsmasq_mk}" 2>/dev/null || true
        echo "Dnsmasq synced to v${dnsmasq_ver}"
    fi

    # 7. 同步最新 Argon 主题
    setup_lucky_argon_theme
}

setup_lucky_feeds
echo "Standalone Part 1 feed preparation for 6.18 LUCKY completed."
