#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/common-feed-setup.sh"

setup_common_feeds

# Expose pcre2 from the packages feed in the main tree as well. The 6.18 build
# line pulls in proxy packages from `helloworld` that require libpcre2, while
# lede core packages may resolve dependencies before feed-installed package
# links are available.
if [ -d "feeds/packages/libs/pcre2" ]; then
    rm -rf package/libs/pcre2
    cp -a feeds/packages/libs/pcre2 package/libs/pcre2
fi

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
