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

    # 拉取最新的 Honk 与 luci-app-honk 专属软件包源码（增加 3 次自动重试与哈希防崩机制）
    rm -rf package/openwrt-honk package/honk feeds/luci/applications/luci-app-honk package/feeds/*/luci-app-honk 2>/dev/null || true
    local clone_success=0
    for i in 1 2 3; do
        if clone_package_repo "https://github.com/kenzok8/openwrt-honk.git" "package/openwrt-honk" "main"; then
            clone_success=1
            break
        fi
        echo "克隆 openwrt-honk 失败 (第 $i 次/共 3 次)，3 秒后重试..."
        sleep 3
    done
    [ "$clone_success" -eq 1 ] || { echo "ERROR: 无法克隆 openwrt-honk 仓库源码"; exit 1; }

    # 防止上游发布新 release 时资源重新打包导致 PKG_HASH 校验失败中断编译
    find package/openwrt-honk -type f -name "Makefile" | while read -r mk; do
        sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/g' "$mk" 2>/dev/null || true
        sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/g' "$mk" 2>/dev/null || true
    done

    echo "HONK tracking upstream latest: Tag=${honk_tag:-none}, Commit=${honk_commit:-HEAD}"

    # 清除 HomeProxy 与 sing-box 源码包，确保纯净无冲突
    rm -rf package/homeproxy feeds/luci/applications/luci-app-homeproxy package/feeds/luci/luci-app-homeproxy 2>/dev/null || true
    rm -rf feeds/packages/net/sing-box package/feeds/packages/sing-box 2>/dev/null || true

    echo "6.18 HONK package sources pinned to upstream latest."
}

setup_common_feeds
pin_honk_package_sources

echo "Part 1 feed preparation for 6.18 HONK completed."
