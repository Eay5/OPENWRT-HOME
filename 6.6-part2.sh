##!/bin/bash
###
 # @Author: eay
 # @Date: 2022-01-13 14:44:27
 # @LastEditors: eay 1015714710@qq.com
 # @Autor: Seven
 # @LastEditTime: 2023-05-16 23:35:35
 # @Description: 
### 
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
 
#ip
sed -i 's/192.168.1.1/192.168.0.133/g' openwrt/package/base-files/files/bin/config_generate
# 编译5.10
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=6.6/g' target/linux/x86/Makefile
#2. Clear the login password
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings
#4.an-theme
#取消bootstrap为默认主题：
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
#name
sed -i "s/hostname='LEDE'/hostname='EAY'/g" openwrt/package/base-files/files/bin/config_generate

 
