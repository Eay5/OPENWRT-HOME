#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/common-proxy-verification.sh"

echo "Applying basic settings..."

sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.18/g' target/linux/x86/Makefile

if [ -f package/libs/libselinux/Makefile ]; then
    sed -i 's/HOST_BUILD_DEPENDS:=libsepol\/host musl-fts\/host pcre2\/host/HOST_BUILD_DEPENDS:=libsepol\/host musl-fts\/host pcre\/host/' package/libs/libselinux/Makefile
    sed -i 's/DEPENDS:=+libsepol +libpcre2 +USE_MUSL:musl-fts/DEPENDS:=+libsepol +libpcre +USE_MUSL:musl-fts/' package/libs/libselinux/Makefile

    if ! grep -q 'USE_PCRE2=n' package/libs/libselinux/Makefile; then
        perl -0pi -e 's/MAKE_FLAGS \+= \\\n\tSHLIBDIR=\/usr\/lib \\\n\tOS=Linux/MAKE_FLAGS += \\\n\tUSE_PCRE2=n \\\n\tSHLIBDIR=\/usr\/lib \\\n\tOS=Linux/s' package/libs/libselinux/Makefile
    fi
fi

sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i "s/hostname='LEDE'/hostname='EAY'/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='OpenWrt'/hostname='EAY'/g" package/base-files/files/bin/config_generate

echo "Basic settings applied."
verify_proxy_stack "6.18" "1"

echo ""
echo "======================================"
echo "OpenWrt 6.18 configuration complete"
echo "======================================"
echo "  - Kernel: 6.18"
echo "  - Default IP: 192.168.0.133"
echo "  - Hostname: EAY"
echo "  - Theme: Argon"
echo "  - Performance defaults: governor/EPP performance, irqbalance, packet steering, RPS/XPS, flow offload, BBR"
echo "  - Proxy stack: SSR-Plus (iptables backend)"
echo "  - Apps: SSR-Plus, MosDNS, SmartDNS"
echo "======================================"
