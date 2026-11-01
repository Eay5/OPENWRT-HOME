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

    rm -rf feeds/luci/themes/luci-theme-argon
    rm -rf package/feeds/luci/luci-theme-argon
    rm -rf package/luci-theme-argon
    rm -rf package/luci-app-argon-config
    rm -rf feeds/luci/applications/luci-app-argon-config
    rm -rf package/feeds/luci/luci-app-argon-config
    clone_package_repo "https://github.com/jerrykuku/luci-theme-argon.git" "package/luci-theme-argon" "master"
    find package/luci-theme-argon -type f -name "footer*.ut" -exec sed -i -E 's/\{# vPKG_VERSION #\}/v3.0.0/g' {} + 2>/dev/null || true

    # 拉取最新的 Honk 与 luci-app-honk 专属软件包源码
    rm -rf package/openwrt-honk package/honk feeds/luci/applications/luci-app-honk package/feeds/*/luci-app-honk 2>/dev/null || true
    clone_package_repo "https://github.com/kenzok8/openwrt-honk.git" "package/openwrt-honk" "main"

    # 清除 HomeProxy 与 sing-box 源码包，确保纯净无冲突
    rm -rf package/homeproxy feeds/luci/applications/luci-app-homeproxy package/feeds/luci/luci-app-homeproxy 2>/dev/null || true
    rm -rf feeds/packages/net/sing-box package/feeds/packages/sing-box 2>/dev/null || true

    echo "6.18 HONK package sources pinned."
}

setup_common_feeds
pin_honk_package_sources

echo "Part 1 feed preparation for 6.18 HONK completed."

