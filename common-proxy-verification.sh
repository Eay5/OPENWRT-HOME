#!/bin/bash

verify_proxy_stack() {
    local kernel_series="$1"
    local require_iptables_proxy="${2:-0}"

    echo ""
    echo "=== Verifying required proxy packages ==="

    if grep -q '^CONFIG_PACKAGE_luci-app-ssr-plus=y' .config; then
        echo "SSR-Plus enabled in .config"
    else
        echo "ERROR: luci-app-ssr-plus is disabled in .config"
        exit 1
    fi

    if [ "${require_iptables_proxy}" = "1" ]; then
        if grep -q '^CONFIG_PACKAGE_luci-app-ssr-plus_Iptables_Transparent_Proxy=y' .config; then
            echo "SSR-Plus iptables backend enabled"
        else
            echo "ERROR: SSR-Plus iptables backend is missing in .config"
            exit 1
        fi
    fi

    if [ -d "feeds/helloworld/luci-app-ssr-plus" ]; then
        echo "SSR-Plus source: fw876/helloworld"
    else
        echo "ERROR: fw876/helloworld luci-app-ssr-plus not found"
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

    if grep -q '^CONFIG_PACKAGE_luci-app-smartdns=y' .config && grep -q '^CONFIG_PACKAGE_smartdns=y' .config; then
        echo "SmartDNS enabled in .config"
    else
        echo "ERROR: SmartDNS is not fully enabled in .config"
        exit 1
    fi

    if [ -d "feeds/luci/applications/luci-app-smartdns" ] && [ -d "feeds/packages/net/smartdns" ]; then
        echo "SmartDNS source: official OpenWrt feeds"
    else
        echo "ERROR: official SmartDNS packages not found"
        exit 1
    fi

    if grep -q '^CONFIG_PACKAGE_smartdns-ui=n' .config; then
        echo "smartdns-ui kept disabled"
    fi

    echo "Proxy stack verified for kernel ${kernel_series}"
}
