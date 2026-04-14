#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/common-proxy-verification.sh"

target_kernel_series="6.18"
target_default_ip="192.168.0.133"
target_hostname="EAY"

config_is_enabled() {
    local key="$1"

    grep -q "^${key}=y$" .config 2>/dev/null
}

join_by_comma() {
    local joined=""
    local item

    for item in "$@"; do
        [ -n "$item" ] || continue

        if [ -n "$joined" ]; then
            joined="${joined}, ${item}"
        else
            joined="${item}"
        fi
    done

    printf '%s\n' "${joined:-none detected}"
}

to_title_case() {
    local value="$1"

    echo "$value" | tr '-' ' ' | awk '{
        for (i = 1; i <= NF; i++) {
            $i = toupper(substr($i, 1, 1)) substr($i, 2)
        }
        print
    }'
}

detect_kernel_version() {
    local patchver
    local kernel_file
    local kernel_pattern
    local kernel_version

    patchver="$(sed -n 's/^KERNEL_PATCHVER:=//p' target/linux/x86/Makefile | head -n 1 | tr -d '\r')"
    [ -n "$patchver" ] || patchver="$target_kernel_series"

    kernel_file="include/kernel-${patchver}"
    kernel_pattern="${patchver//./\\.}"
    kernel_version=""

    if [ -f "$kernel_file" ]; then
        kernel_version="$(sed -n "s/^LINUX_VERSION-${kernel_pattern}[[:space:]]*[:?]?=[[:space:]]*//p" "$kernel_file" | head -n 1 | tr -d '\r')"
    fi

    case "$kernel_version" in
        "")
            echo "$patchver"
            ;;
        .*)
            echo "${patchver}${kernel_version}"
            ;;
        [0-9]*)
            echo "${patchver}.${kernel_version}"
            ;;
        *)
            echo "$kernel_version"
            ;;
    esac
}

detect_default_ip() {
    local ip

    ip="$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' package/base-files/files/bin/config_generate 2>/dev/null | head -n 1 || true)"
    echo "${ip:-unknown}"
}

detect_hostname() {
    local hostname

    hostname="$(sed -n "s/.*hostname='\([^']*\)'.*/\1/p" package/base-files/files/bin/config_generate 2>/dev/null | tail -n 1)"
    echo "${hostname:-unknown}"
}

detect_theme() {
    local theme_pkg

    theme_pkg="$(grep -oE '^CONFIG_PACKAGE_luci-theme-[^=]+=y$' .config 2>/dev/null | head -n 1 | sed -E 's/^CONFIG_PACKAGE_(luci-theme-[^=]+)=y$/\1/' || true)"

    if [ -z "$theme_pkg" ] && [ -f feeds/luci/collections/luci/Makefile ]; then
        theme_pkg="$(grep -oE 'luci-theme-[a-zA-Z0-9_-]+' feeds/luci/collections/luci/Makefile 2>/dev/null | head -n 1 || true)"
    fi

    if [ -z "$theme_pkg" ]; then
        echo "unknown"
        return
    fi

    to_title_case "${theme_pkg#luci-theme-}"
}

detect_performance_defaults() {
    local items=()

    if [ -f files/etc/init.d/performance-mode ]; then
        items+=("governor/EPP performance")
    fi

    if config_is_enabled CONFIG_PACKAGE_irqbalance; then
        items+=("irqbalance")
    fi

    if [ -f files/etc/uci-defaults/99-system-performance ] && grep -q "packet_steering='1'" files/etc/uci-defaults/99-system-performance; then
        items+=("packet steering")
    fi

    if [ -f files/etc/init.d/performance-mode ] && grep -q 'rps_cpus' files/etc/init.d/performance-mode && grep -q 'xps_cpus' files/etc/init.d/performance-mode; then
        items+=("RPS/XPS")
    fi

    if [ -f files/etc/uci-defaults/99-system-performance ] && grep -q "flow_offloading='1'" files/etc/uci-defaults/99-system-performance; then
        items+=("flow offload")
    fi

    if config_is_enabled CONFIG_PACKAGE_kmod-tcp-bbr || { [ -f files/etc/init.d/performance-mode ] && grep -q 'tcp_congestion_control=bbr' files/etc/init.d/performance-mode; }; then
        items+=("BBR")
    fi

    join_by_comma "${items[@]}"
}

detect_proxy_stack() {
    if config_is_enabled CONFIG_PACKAGE_luci-app-ssr-plus_Iptables_Transparent_Proxy; then
        echo "SSR-Plus (iptables backend)"
    elif config_is_enabled CONFIG_PACKAGE_luci-app-ssr-plus_Nftables_Transparent_Proxy; then
        echo "SSR-Plus (nftables backend)"
    elif config_is_enabled CONFIG_PACKAGE_luci-app-ssr-plus; then
        echo "SSR-Plus"
    else
        echo "not detected"
    fi
}

detect_enabled_apps() {
    local apps=()

    config_is_enabled CONFIG_PACKAGE_luci-app-ssr-plus && apps+=("SSR-Plus")
    config_is_enabled CONFIG_PACKAGE_luci-app-mosdns && apps+=("MosDNS")
    config_is_enabled CONFIG_PACKAGE_luci-app-smartdns && apps+=("SmartDNS")
    config_is_enabled CONFIG_PACKAGE_luci-app-adguardhome && apps+=("AdGuardHome")

    join_by_comma "${apps[@]}"
}

detect_nic_drivers() {
    local drivers=()

    config_is_enabled CONFIG_PACKAGE_kmod-e1000 && drivers+=("Intel e1000")
    config_is_enabled CONFIG_PACKAGE_kmod-e1000e && drivers+=("Intel e1000e")
    config_is_enabled CONFIG_PACKAGE_kmod-igb && drivers+=("Intel igb")
    config_is_enabled CONFIG_PACKAGE_kmod-igc && drivers+=("Intel igc 2.5G")
    config_is_enabled CONFIG_PACKAGE_kmod-r8125 && drivers+=("Realtek r8125 2.5G")
    config_is_enabled CONFIG_PACKAGE_kmod-r8169 && drivers+=("Realtek r8169")
    config_is_enabled CONFIG_PACKAGE_kmod-virtio-net && drivers+=("Virtio net")

    join_by_comma "${drivers[@]}"
}

echo "Applying basic settings..."

sed -i "s/192\\.168\\.1\\.1/${target_default_ip}/g" package/base-files/files/bin/config_generate
sed -i "s/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=${target_kernel_series}/g" target/linux/x86/Makefile

if [ -f package/libs/libselinux/Makefile ]; then
    sed -i 's/HOST_BUILD_DEPENDS:=libsepol\/host musl-fts\/host pcre2\/host/HOST_BUILD_DEPENDS:=libsepol\/host musl-fts\/host pcre\/host/' package/libs/libselinux/Makefile
    sed -i 's/DEPENDS:=+libsepol +libpcre2 +USE_MUSL:musl-fts/DEPENDS:=+libsepol +libpcre +USE_MUSL:musl-fts/' package/libs/libselinux/Makefile

    if ! grep -q 'USE_PCRE2=n' package/libs/libselinux/Makefile; then
        perl -0pi -e 's/MAKE_FLAGS \+= \\\n\tSHLIBDIR=\/usr\/lib \\\n\tOS=Linux/MAKE_FLAGS += \\\n\tUSE_PCRE2=n \\\n\tSHLIBDIR=\/usr\/lib \\\n\tOS=Linux/s' package/libs/libselinux/Makefile
    fi
fi

sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i "s/hostname='LEDE'/hostname='${target_hostname}'/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='OpenWrt'/hostname='${target_hostname}'/g" package/base-files/files/bin/config_generate

echo "Basic settings applied."
verify_proxy_stack "${target_kernel_series}" "1"

kernel_display="$(detect_kernel_version)"
default_ip_display="$(detect_default_ip)"
hostname_display="$(detect_hostname)"
theme_display="$(detect_theme)"
performance_display="$(detect_performance_defaults)"
proxy_stack_display="$(detect_proxy_stack)"
apps_display="$(detect_enabled_apps)"
nic_drivers_display="$(detect_nic_drivers)"

echo ""
echo "======================================"
echo "OpenWrt ${kernel_display} configuration complete"
echo "======================================"
echo "  - Kernel: ${kernel_display}"
echo "  - Default IP: ${default_ip_display}"
echo "  - Hostname: ${hostname_display}"
echo "  - Theme: ${theme_display}"
echo "  - NIC drivers: ${nic_drivers_display}"
echo "  - Performance defaults: ${performance_display}"
echo "  - Proxy stack: ${proxy_stack_display}"
echo "  - Apps: ${apps_display}"
echo "======================================"
