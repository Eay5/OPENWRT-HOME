#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 修改默认IP
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate

# 编译6.12内核
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=6.12/g' target/linux/x86/Makefile

# 清除登录密码
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings

# 取消bootstrap为默认主题，改为argone
sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' feeds/luci/collections/luci/Makefile

# 修改主机名
sed -i "s/hostname='LEDE'/hostname='EAY'/g" package/base-files/files/bin/config_generate

# 确保 SSR Plus+ 相关包的 Makefile 正确
echo "Verifying SSR Plus+ packages..."
if [ -d "feeds/small/shadowsocks-libev" ]; then
    echo "shadowsocks-libev found in small feed"
fi
if [ -d "feeds/small/simple-obfs" ]; then
    echo "simple-obfs found in small feed"
fi

# 修复可能的依赖问题
echo "Fixing potential dependency issues..."
# 确保 feeds 配置正确
./scripts/feeds install -a

# 特别确保 SSR Plus+ 及其依赖被正确安装
./scripts/feeds install luci-app-ssr-plus
./scripts/feeds install shadowsocks-libev-ss-local
./scripts/feeds install shadowsocks-libev-ss-redir
./scripts/feeds install shadowsocks-libev-ss-server
./scripts/feeds install shadowsocksr-libev-ssr-local
./scripts/feeds install shadowsocksr-libev-ssr-redir
./scripts/feeds install shadowsocksr-libev-ssr-server
./scripts/feeds install simple-obfs
./scripts/feeds install v2ray-core
./scripts/feeds install xray-core
./scripts/feeds install trojan-plus