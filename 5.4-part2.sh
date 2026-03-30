#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/common-proxy-verification.sh"

echo "Applying basic settings..."

sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=5.4/g' target/linux/x86/Makefile
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i "s/hostname='LEDE'/hostname='EAY'/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='OpenWrt'/hostname='EAY'/g" package/base-files/files/bin/config_generate

echo "Basic settings applied."
verify_proxy_stack "5.4" "0"

echo ""
echo "======================================"
echo "OpenWrt 5.4 configuration complete"
echo "======================================"
echo "  - Kernel: 5.4"
echo "  - Default IP: 192.168.0.133"
echo "  - Hostname: EAY"
echo "  - Theme: Argon"
echo "  - Apps: SSR-Plus, MosDNS, SmartDNS"
echo "======================================"
