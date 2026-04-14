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

    rm -rf package/lean/luci-theme-argon
    rm -rf package/lean/luci-app-argon-config
    rm -rf feeds/kenzo/luci-theme-argon
    rm -rf feeds/kenzo/luci-app-argon-config
    rm -rf package/feeds/kenzo/luci-theme-argon
    rm -rf package/feeds/kenzo/luci-app-argon-config
    # The legacy 18.06 Argon branches still use old LuCI Lua templates and
    # dispatcher internals (`__entries`), which crash on the current 6.18 LuCI
    # stack. Pull the maintained branch instead.
    clone_package_repo "https://github.com/jerrykuku/luci-theme-argon.git" "package/luci-theme-argon"
    clone_package_repo "https://github.com/jerrykuku/luci-app-argon-config.git" "package/luci-app-argon-config"

    rm -rf feeds/luci/applications/luci-app-smartdns
    rm -rf package/feeds/luci/luci-app-smartdns
    rm -rf feeds/packages/net/smartdns
    rm -rf package/feeds/packages/smartdns
    rm -rf feeds/kenzo/luci-app-smartdns
    rm -rf package/feeds/kenzo/luci-app-smartdns
    rm -rf feeds/kenzo/smartdns
    rm -rf package/feeds/kenzo/smartdns
    clone_package_repo "https://github.com/pymumu/openwrt-smartdns.git" "package/smartdns"
    sed -i 's#^include ../../lang/rust/rust-package.mk$#include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk#' package/smartdns/Makefile
    clone_package_repo "https://github.com/pymumu/luci-app-smartdns.git" "package/luci-app-smartdns" "lede"

    echo "6.18 package sources pinned."
}

setup_common_feeds

# Expose pcre2 from the packages feed in the main tree as well. The 6.18 build
# line pulls in proxy packages from `helloworld` that require libpcre2, while
# lede core packages may resolve dependencies before feed-installed package
# links are available.
if [ -d "feeds/packages/libs/pcre2" ]; then
    rm -rf package/libs/pcre2
    cp -a feeds/packages/libs/pcre2 package/libs/pcre2
fi

pin_618_package_sources

echo "Removing KSMBD-related packages..."
rm -rf feeds/*/luci-app-ksmbd
rm -rf feeds/*/ksmbd-server
rm -rf feeds/*/ksmbd-utils
rm -rf feeds/luci/applications/luci-app-ksmbd
rm -rf feeds/packages/net/ksmbd-tools
rm -rf package/feeds/*/luci-app-ksmbd
rm -rf package/feeds/*/ksmbd*
rm -rf feeds/*/autosamba
rm -rf package/feeds/*/autosamba
rm -rf package/lean/autosamba

echo "Feed cleanup completed."
