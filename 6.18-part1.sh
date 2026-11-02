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

    # 动态拉取并同步 luci-theme-argon 最新上游版本
    setup_argon_theme

    echo "6.18 package sources pinned."
}

setup_common_feeds
pin_618_package_sources

echo "Part 1 feed preparation completed."
