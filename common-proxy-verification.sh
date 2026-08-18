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

    if [ -d "feeds/helloworld/luci-app-ssr-plus" ] || [ -d "package/feeds/helloworld/luci-app-ssr-plus" ] || [ -d "package/helloworld" ]; then
        echo "SSR-Plus source: fw876/helloworld"
    else
        echo "ERROR: SSR-Plus package source not found"
        exit 1
    fi

    if grep -q '^CONFIG_PACKAGE_luci-app-mosdns=y' .config && grep -q '^CONFIG_PACKAGE_mosdns=y' .config; then
        echo "MosDNS enabled in .config"
    else
        echo "ERROR: MosDNS is not fully enabled in .config"
        exit 1
    fi

    if [ -d "package/mosdns/luci-app-mosdns" ] || [ -d "package/mosdns" ]; then
        echo "MosDNS source: sbwml/luci-app-mosdns v5"
    else
        echo "ERROR: sbwml/luci-app-mosdns v5 not found"
        exit 1
    fi

    if grep -q '^CONFIG_PACKAGE_smartdns=y' .config; then
        echo "SmartDNS enabled in .config"
    fi

    echo "Proxy stack verified for kernel ${kernel_series}"
}
