##!/bin/bash
###
 # @Author: eay
 # @Date: 2022-01-13 14:44:27
 # @LastEditors: eay 1015714710@qq.com
 # @Autor: Seven
 # @LastEditTime: 2022-07-13 06:23:42
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
sed -i 's/192.168.1.1/10.10.10.133/g' ./package/base-files/files/bin/config_generate
# 编译5.10
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=6.1/g' ./target/linux/x86/Makefile
#2. Clear the login password
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' ./package/lean/default-settings/files/zzz-default-settings
#4.an-theme
#取消bootstrap为默认主题：
#sed -i 's/luci-theme-bootstrap/luci-theme-argon-jerrykuku/g' ./feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argonne/g' ./feeds/luci/collections/luci/Makefile
#name
sed -i "s/hostname='OpenWrt'/hostname='OpenWrt-eay'/g" ./package/base-files/files/bin/config_generate
sed -i "s/local rv = {/	local weekTab = { ["0"] = '星期天',["1"] = '星期一',["2"] = '星期二',["3"] = '星期三',["4"] = '星期四',["5"] = '星期五',["6"] = '星期六'}
local rv = {/g" ./package/lean/autocore/files/x86/index
sed -i "s/os.date()/os.date("%Y-%m-%d %H:%M:%S ", os.time()).. weekTab[tostring(os.date("%w", os.time()))]/g" ./package/lean/autocore/files/x86/index
 