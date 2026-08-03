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

    if [ -d "package/helloworld" ] || [ -d "feeds/kenzo/luci-app-ssr-plus" ] || [ -d "package/feeds/kenzo/luci-app-ssr-plus" ]; then
        echo "SSR-Plus source: fw876/helloworld"
    else
        echo "ERROR: SSR-Plus package not found"
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
        echo "SmartDNS disabled in .config (SSR-Plus + MosDNS stack)"
    fi

    echo "Proxy stack verified for kernel ${kernel_series}"
}
