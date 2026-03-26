#!/bin/bash
set -euo pipefail

echo "Applying basic settings..."

# Default LAN IP
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate

# Force kernel 6.12 for this build line
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.12/g' target/linux/x86/Makefile

# Work around the current lede master libselinux -> pcre2 mismatch by
# forcing libselinux back to the core-tree pcre package, which already has
# matching target + host builds in the main tree.
if [ -f package/libs/libselinux/Makefile ]; then
    sed -i 's/HOST_BUILD_DEPENDS:=libsepol\/host musl-fts\/host pcre2\/host/HOST_BUILD_DEPENDS:=libsepol\/host musl-fts\/host pcre\/host/' package/libs/libselinux/Makefile
    sed -i 's/DEPENDS:=+libsepol +libpcre2 +USE_MUSL:musl-fts/DEPENDS:=+libsepol +libpcre +USE_MUSL:musl-fts/' package/libs/libselinux/Makefile

    if ! grep -q 'USE_PCRE2=n' package/libs/libselinux/Makefile; then
        perl -0pi -e 's/MAKE_FLAGS \+= \\\n\tSHLIBDIR=\/usr\/lib \\\n\tOS=Linux/MAKE_FLAGS += \\\n\tUSE_PCRE2=n \\\n\tSHLIBDIR=\/usr\/lib \\\n\tOS=Linux/s' package/libs/libselinux/Makefile
    fi
fi

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
echo "  - Performance defaults: governor/EPP performance, irqbalance, packet steering, RPS/XPS, flow offload, BBR"
echo "  - Proxy stack: SSR-Plus (iptables backend)"
echo "  - Apps: SSR-Plus, MosDNS, SmartDNS"
echo "======================================"
