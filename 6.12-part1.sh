#!/bin/bash
set -euo pipefail

add_or_replace_feed() {
    local name="$1"
    local url="$2"

    sed -i "\|^src-git ${name} |d" feeds.conf.default
    sed -i "1i src-git ${name} ${url}" feeds.conf.default
}

echo "Adding custom feeds..."
add_or_replace_feed "small" "https://github.com/kenzok8/small"
add_or_replace_feed "kenzo" "https://github.com/kenzok8/openwrt-packages"

echo "Updated feeds.conf.default:"
cat feeds.conf.default

./scripts/feeds update -a

echo "Removing conflicting packages..."

# Prefer small for MosDNS and proxy runtimes.
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf package/feeds/luci/luci-app-mosdns
rm -rf feeds/packages/net/{adguardhome,mosdns,xray*,v2ray*,sing*}
rm -rf package/feeds/packages/{adguardhome,mosdns,xray*,v2ray*,sing*}
rm -rf feeds/packages/utils/v2dat
rm -rf package/feeds/packages/v2dat

# Remove Alist front-end together with the backend to avoid broken feed warnings.
rm -rf feeds/luci/applications/luci-app-alist
rm -rf package/feeds/luci/luci-app-alist
rm -rf feeds/packages/net/alist
rm -rf package/feeds/packages/alist

# Match the 5.10/5.15 layout: keep the kenzo SmartDNS stack together.
rm -rf feeds/packages/net/smartdns
rm -rf package/feeds/packages/smartdns

# Replace Golang with the sbwml 25.x tree.
rm -rf feeds/packages/lang/golang
rm -rf package/feeds/packages/golang
git clone --depth 1 -b 25.x https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# Remove known conflicting LuCI apps from third-party feeds.
rm -rf feeds/luci/applications/luci-app-fchomo
rm -rf feeds/luci/applications/luci-app-bypass
rm -rf package/feeds/luci/luci-app-fchomo
rm -rf package/feeds/luci/luci-app-bypass
rm -rf feeds/kenzo/luci-app-fchomo
rm -rf feeds/kenzo/luci-app-bypass
rm -rf feeds/small/luci-app-fchomo
rm -rf feeds/small/luci-app-bypass

# Remove KSMBD and packages that still default to it.
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
