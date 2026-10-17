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

pin_618_package_sources() {
    echo "Pinning 6.18 package sources..."

    rm -rf feeds/luci/themes/luci-theme-argon
    rm -rf package/feeds/luci/luci-theme-argon
    rm -rf package/luci-theme-argon
    rm -rf package/luci-app-argon-config
    rm -rf feeds/luci/applications/luci-app-argon-config
    rm -rf package/feeds/luci/luci-app-argon-config
    clone_package_repo "https://github.com/jerrykuku/luci-theme-argon.git" "package/luci-theme-argon" "master"
    find package/luci-theme-argon -type f -name "footer*.ut" -exec sed -i -E 's/\{# vPKG_VERSION #\}/v3.0.0/g' {} + 2>/dev/null || true

    echo "6.18 package sources pinned."
}

setup_common_feeds
pin_618_package_sources

echo "Part 1 feed preparation completed."
