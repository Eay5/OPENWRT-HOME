#!/bin/bash

verify_proxy_stack() {
    local kernel_series="$1"
    local require_iptables_proxy="${2:-0}"

    echo ""
    echo "=== Verifying required proxy packages ==="

    if grep -q '^CONFIG_PACKAGE_luci-app-passwall=y' .config; then
        echo "PassWall enabled in .config"
    else
        echo "ERROR: luci-app-passwall is disabled in .config"
        exit 1
    fi

    if [ -d "package/passwall-luci" ] || [ -d "package/passwall-packages" ] || [ -d "feeds/passwall" ] || [ -d "package/feeds/passwall" ]; then
        echo "PassWall source: xiaorouji/openwrt-passwall"
    else
        echo "ERROR: PassWall package source not found"
        exit 1
    fi

    if grep -q '^CONFIG_PACKAGE_luci-app-mosdns=y' .config && grep -q '^CONFIG_PACKAGE_mosdns=y' .config; then
        echo "MosDNS enabled in .config"
    fi

    if grep -q '^CONFIG_PACKAGE_smartdns=y' .config; then
        echo "SmartDNS enabled in .config"
    fi

    echo "Proxy stack verified for kernel ${kernel_series}"
}
