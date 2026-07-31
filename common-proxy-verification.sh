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

    if [ -d "package/passwall" ] || [ -d "package/passwall/luci-app-passwall" ] || [ -d "feeds/luci/applications/luci-app-passwall" ] || [ -d "package/feeds/luci/luci-app-passwall" ]; then
        echo "PassWall source: Openwrt-Passwall/openwrt-passwall"
    else
        echo "ERROR: PassWall package not found"
        exit 1
    fi

    if grep -q '^CONFIG_PACKAGE_luci-app-mosdns=y' .config && grep -q '^CONFIG_PACKAGE_mosdns=y' .config; then
        echo "MosDNS enabled in .config"
    else
        echo "ERROR: MosDNS is not fully enabled in .config"
        exit 1
    fi

    if [ -d "package/mosdns/luci-app-mosdns" ]; then
        echo "MosDNS source: sbwml/luci-app-mosdns v5"
    else
        echo "ERROR: sbwml/luci-app-mosdns v5 not found"
        exit 1
    fi

    if grep -q '^CONFIG_PACKAGE_smartdns=n' .config; then
        echo "SmartDNS disabled in .config (PassWall + MosDNS stack)"
    fi

    echo "Proxy stack verified for kernel ${kernel_series}"
}
