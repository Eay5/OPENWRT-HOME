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

# Remove proxy runtimes from the official feeds so we can pin the 6.12 SSR-Plus
# toolchain to the small feed variants instead of mixing multiple third-party
# package families together.
rm -rf feeds/packages/net/{adguardhome,mosdns,xray*,v2ray*,sing*,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf package/feeds/packages/{adguardhome,mosdns,xray*,v2ray*,sing*}
rm -rf feeds/packages/utils/v2dat
rm -rf package/feeds/packages/v2dat

# Use sbwml/luci-app-mosdns v5 instead of kenzok8's version.
# Remove ALL existing mosdns & v2ray-geodata from every source.
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf package/feeds/luci/luci-app-mosdns
rm -rf feeds/kenzo/luci-app-mosdns
rm -rf feeds/small/luci-app-mosdns
rm -rf feeds/small/mosdns
rm -rf feeds/kenzo/mosdns
find ./ -path '*/Makefile' | xargs grep -l 'mosdns' | xargs rm -f 2>/dev/null || true
find ./ -path '*/Makefile' | xargs grep -l 'v2ray-geodata' | xargs rm -f 2>/dev/null || true
git clone --depth 1 https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone --depth 1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# Remove Alist front-end together with the backend to avoid broken feed warnings.
rm -rf feeds/luci/applications/luci-app-alist
rm -rf package/feeds/luci/luci-app-alist
rm -rf feeds/packages/net/alist
rm -rf package/feeds/packages/alist

# Prefer the official SmartDNS stack on 6.12. The kenzo variant currently
# triggers rust-bindgen/host warnings on lede master and is not needed here.
rm -rf feeds/kenzo/smartdns
rm -rf package/feeds/kenzo/smartdns
rm -rf feeds/kenzo/luci-app-smartdns
rm -rf package/feeds/kenzo/luci-app-smartdns

# Replace Golang with the sbwml 25.x tree.
rm -rf feeds/packages/lang/golang
rm -rf package/feeds/packages/golang
git clone --depth 1 -b 25.x https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# Expose pcre2 from the packages feed in the main tree as well. The 6.12 build
# line pulls in proxy packages from `small` that require libpcre2, while lede
# core packages may resolve dependencies before feed-installed package links are
# available. Keeping a copy in package/libs makes the dependency visible early
# and avoids ssr-plus being dropped during defconfig.
if [ -d "feeds/packages/libs/pcre2" ]; then
rm -rf package/libs/pcre2
cp -a feeds/packages/libs/pcre2 package/libs/pcre2
fi

# Remove known conflicting LuCI apps from third-party feeds.
rm -rf feeds/luci/applications/luci-app-fchomo
rm -rf feeds/luci/applications/luci-app-bypass
rm -rf package/feeds/luci/luci-app-fchomo
rm -rf package/feeds/luci/luci-app-bypass
rm -rf feeds/kenzo/luci-app-fchomo
rm -rf feeds/kenzo/luci-app-bypass
rm -rf feeds/kenzo/luci-app-mosdns
rm -rf feeds/kenzo/luci-app-openclaw
rm -rf feeds/small/luci-app-fchomo
rm -rf feeds/small/luci-app-bypass
rm -rf feeds/small/luci-app-mosdns

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
