#!/bin/bash
set -euo pipefail

install_from_feed() {
    local feed="$1"
    shift
    local pkg

    for pkg in "$@"; do
        echo "Installing ${pkg} from ${feed}..."
        ./scripts/feeds install -p "${feed}" "${pkg}"
    done
}

force_config() {
    local symbol="$1"
    local value="$2"

    touch .config
    sed -i "/^${symbol}=.*/d" .config
    sed -i "/^# ${symbol} is not set$/d" .config
    echo "${symbol}=${value}" >> .config
}

echo "Applying base settings..."
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.12/g' target/linux/x86/Makefile
sed -i "s/hostname='OpenWrt'/hostname='EAY'/g" package/base-files/files/bin/config_generate
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

echo "Installing pinned feed packages..."
install_from_feed small \
    luci-app-ssr-plus \
    shadowsocks-libev \
    shadowsocks-rust \
    shadowsocksr-libev \
    simple-obfs \
    v2ray-core \
    v2ray-plugin \
    xray-core \
    xray-plugin \
    trojan-plus \
    trojan-go \
    dns2socks \
    dns2tcp \
    ipt2socks \
    redsocks2 \
    pdnsd-alt \
    chinadns-ng \
    mosdns \
    luci-app-mosdns

install_from_feed packages smartdns

install_from_feed kenzo \
    luci-app-smartdns \
    luci-theme-argon

force_config CONFIG_PACKAGE_autosamba n

echo
echo "======================================"
echo "OpenWrt 6.12 package setup completed."
echo "  Kernel : 6.12"
echo "  IP     : 192.168.0.133"
echo "  Host   : EAY"
echo "  Theme  : Argon"
echo "======================================"
