#!/bin/bash
set -euo pipefail

echo "Applying basic settings..."

# Default LAN IP
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate

# Force kernel 6.12 for this build line
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.12/g' target/linux/x86/Makefile

# Clear default root password hash if the file exists
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true

# Switch default LuCI theme to Argon
sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# Set hostname
sed -i "s/hostname='LEDE'/hostname='EAY'/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='OpenWrt'/hostname='EAY'/g" package/base-files/files/bin/config_generate

echo "Basic settings applied."
echo ""
echo "=== Verifying critical packages ==="

if grep -q '^CONFIG_PACKAGE_luci-app-ssr-plus=y' .config && grep -q '^CONFIG_PACKAGE_luci-app-ssr-plus_Iptables_Transparent_Proxy=y' .config; then
    echo "SSR-Plus + iptables transparent proxy enabled"
else
    echo "WARNING: SSR-Plus iptables backend is missing in .config"
fi

if [ -d "package/mosdns/luci-app-mosdns" ]; then
    echo "MosDNS (sbwml v5) found"
else
    echo "WARNING: MosDNS (sbwml v5) not found"
fi

if [ -d "feeds/kenzo/luci-app-ssr-plus" ] || [ -d "feeds/small/luci-app-ssr-plus" ]; then
    echo "luci-app-ssr-plus found"
else
    echo "WARNING: luci-app-ssr-plus not found"
fi

if [ -d "feeds/kenzo/luci-app-smartdns" ] || [ -d "feeds/small/smartdns" ]; then
    echo "SmartDNS found"
else
    echo "WARNING: SmartDNS not found"
fi

if grep -q '^CONFIG_PACKAGE_luci-app-passwall=n' .config; then
    echo "Passwall is disabled"
else
    echo "WARNING: Passwall is still enabled in .config"
fi

if grep -q '^CONFIG_PACKAGE_smartdns-ui=n' .config; then
    echo "smartdns-ui is disabled to keep the build lighter"
else
    echo "WARNING: smartdns-ui is still enabled in .config"
fi

echo ""
echo "======================================"
echo "OpenWrt 6.12 configuration complete"
echo "======================================"
echo "  - Kernel: 6.12"
echo "  - Default IP: 192.168.0.133"
echo "  - Hostname: EAY"
echo "  - Theme: Argon"
echo "  - Proxy stack: SSR-Plus (iptables backend)"
echo "  - Apps: SSR-Plus, MosDNS, SmartDNS"
echo "======================================"
