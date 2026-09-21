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

pin_lucky_package_sources() {
    echo "Pinning 6.12 LUCKY package sources..."

    rm -rf feeds/luci/themes/luci-theme-argon
    rm -rf package/feeds/luci/luci-theme-argon
    rm -rf package/luci-theme-argon
    rm -rf package/luci-app-argon-config
    clone_package_repo "https://github.com/jerrykuku/luci-theme-argon.git" "package/luci-theme-argon"
    clone_package_repo "https://github.com/jerrykuku/luci-app-argon-config.git" "package/luci-app-argon-config"

    # 清理非必须插件以加快构建并确保纯净
    rm -rf package/homeproxy feeds/luci/applications/luci-app-homeproxy package/feeds/luci/luci-app-homeproxy 2>/dev/null || true
    rm -rf package/smartdns package/luci-app-smartdns feeds/luci/applications/luci-app-smartdns package/feeds/luci/luci-app-smartdns 2>/dev/null || true

    echo "6.12 LUCKY package sources pinned."
}

setup_common_feeds
pin_lucky_package_sources

echo "Part 1 feed preparation for 6.12 LUCKY completed."
