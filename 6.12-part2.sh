#!/bin/bash
#
# OpenWrt DIY script part 2 (After Update feeds)
# 6.12 kernel version compilation script
#
 
#ip
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate
# 使用6.12内核
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=6.12/g' target/linux/x86/Makefile
#2. Clear the login password
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings
#4.an-theme
#取消bootstrap为默认主题：
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
#name
sed -i "s/hostname='LEDE'/hostname='EAY'/g" package/base-files/files/bin/config_generate

 
