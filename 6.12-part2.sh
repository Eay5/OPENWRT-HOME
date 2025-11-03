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

