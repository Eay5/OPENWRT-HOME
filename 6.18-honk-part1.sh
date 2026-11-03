#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/common-feed-setup.sh"

clone_package_repo() {
    local repo_url="$1"
    local destination="$2"
    local branch="${3:-}"

    rm -rf "${destination}"

    if [ -n "${branch}" ]; then
        git clone --depth 1 -b "${branch}" "${repo_url}" "${destination}"
    else
        git clone --depth 1 "${repo_url}" "${destination}"
    fi
}

pin_honk_package_sources() {
    echo "Pinning 6.18 HONK package sources..."

    # 动态拉取并同步 luci-theme-argon 最新上游版本
    setup_argon_theme

    # 动态追踪 kenzok8/openwrt-honk 上游最新稳定 Release 标签与 main 分支 commit
    local honk_tag=""
    honk_tag=$(git ls-remote --tags --refs https://github.com/kenzok8/openwrt-honk.git 2>/dev/null \
        | grep -v 'candidate' \
        | grep -oE 'refs/tags/v?[0-9]{4}\.[0-9]{2}\.[0-9]{2}[^ ]*$' \
        | sed 's#refs/tags/##' \
        | sort -V \
        | tail -n 1 || true)

    local honk_commit=""
    honk_commit=$(git ls-remote https://github.com/kenzok8/openwrt-honk.git refs/heads/main 2>/dev/null | cut -f1 | head -n 1 || true)

    # 拉取最新的 Honk 与 luci-app-honk 专属软件包源码
    rm -rf package/openwrt-honk package/honk feeds/luci/applications/luci-app-honk package/feeds/*/luci-app-honk 2>/dev/null || true
    clone_package_repo "https://github.com/kenzok8/openwrt-honk.git" "package/openwrt-honk" "main"

    if [ -d "package/openwrt-honk" ]; then
        # 1. 确保所有 Makefile 中的哈希校验跳过，防止每次上游 Release 更新因哈希变动报错中断编译
        find package/openwrt-honk -type f -name "Makefile" | while read -r mk; do
            sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/g' "$mk" 2>/dev/null || true
            sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/g' "$mk" 2>/dev/null || true
        done

        # 2. 动态匹配并更新 Makefile 内部版本号为上游最新 Release
        if [ -n "${honk_tag}" ]; then
            local clean_honk_ver="${honk_tag#v}"
            clean_honk_ver="${clean_honk_ver//.v/.}"
            for mk in package/openwrt-honk/honk/Makefile package/openwrt-honk/luci-app-honk/Makefile; do
                if [ -f "$mk" ]; then
                    local cur_ver
                    cur_ver=$(sed -n 's/^PKG_VERSION:=[[:space:]]*//p' "$mk" 2>/dev/null | head -n 1 | tr -d '\r')
                    if [ -n "$cur_ver" ] && [ "$(printf '%s\n%s' "$cur_ver" "$clean_honk_ver" | sort -V | tail -n 1)" = "$clean_honk_ver" ]; then
                        sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${clean_honk_ver}/g" "$mk" 2>/dev/null || true
                        sed -i "s/^PKG_RELEASE:=.*/PKG_RELEASE:=1/g" "$mk" 2>/dev/null || true
                    fi
                fi
            done
        fi
        echo "HONK tracking upstream latest: Tag=${honk_tag:-none}, Commit=${honk_commit:-HEAD}"
    fi

    # 清除 HomeProxy 与 sing-box 源码包，确保纯净无冲突
    rm -rf package/homeproxy feeds/luci/applications/luci-app-homeproxy package/feeds/luci/luci-app-homeproxy 2>/dev/null || true
    rm -rf feeds/packages/net/sing-box package/feeds/packages/sing-box 2>/dev/null || true

    echo "6.18 HONK package sources pinned to upstream latest."
}

setup_common_feeds
pin_honk_package_sources

echo "Part 1 feed preparation for 6.18 HONK completed."
