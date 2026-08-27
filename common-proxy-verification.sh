#!/bin/bash

verify_proxy_stack() {
    local kernel_series="$1"
    local require_iptables_proxy="${2:-0}"

    echo ""
    echo "=== Verifying required proxy and DNS packages ==="

    if grep -q '^CONFIG_PACKAGE_luci-app-homeproxy=y' .config; then
        echo "HomeProxy enabled in .config"
    else
        echo "ERROR: luci-app-homeproxy is disabled in .config"
        exit 1
    fi

    if grep -q '^CONFIG_PACKAGE_sing-box=y' .config; then
        echo "Sing-box enabled in .config"
    else
        echo "ERROR: sing-box is disabled in .config"
        exit 1
    fi

    if grep -q '^CONFIG_PACKAGE_ucode-mod-math=y' .config; then
        echo "ucode-mod-math enabled in .config"
    else
        echo "ERROR: ucode-mod-math is disabled in .config (required by HomeProxy)"
        exit 1
    fi

    if [ -d "package/homeproxy" ] || [ -d "feeds/luci/applications/luci-app-homeproxy" ] || [ -d "package/feeds/luci/luci-app-homeproxy" ]; then
        echo "HomeProxy package source verified"
    else
        echo "ERROR: HomeProxy package source not found"
        exit 1
    fi

    if grep -q '^CONFIG_PACKAGE_smartdns=y' .config && grep -q '^CONFIG_PACKAGE_luci-app-smartdns=y' .config; then
        echo "SmartDNS enabled in .config"
    else
        echo "ERROR: smartdns / luci-app-smartdns is disabled in .config"
        exit 1
    fi

    if [ -d "package/smartdns" ] && [ -d "package/luci-app-smartdns" ]; then
        echo "SmartDNS package sources verified"
    fi

    echo "Proxy & DNS stack verified for kernel ${kernel_series}"
}
