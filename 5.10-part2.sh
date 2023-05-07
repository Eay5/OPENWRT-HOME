#!/bin/bash
###
 # @Author: eay
 # @Date: 2022-01-13 14:41:53
 # @LastEditors: eay
 # @Autor: Seven
 # @LastEditTime: 2022-03-01 17:30:44
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
#主题
 
 
#ip
sed -i 's/192.168.1.1/10.10.10.133/g' ./package/base-files/files/bin/config_generate
# 编译5.10
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=5.4/g' ./target/linux/x86/Makefile
#2. Clear the login password
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' ./package/lean/default-settings/files/zzz-default-settings
#4.an-theme
#取消bootstrap为默认主题：
sed -i 's/luci-theme-bootstrap/luci-theme-darkmatter/g' ./feeds/luci/collections/luci/Makefile
#name
sed -i "s/hostname='OpenWrt'/hostname='OpenWrt-eay'/g" ./package/base-files/files/bin/config_generate
