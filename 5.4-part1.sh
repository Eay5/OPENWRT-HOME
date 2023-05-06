#!/bin/bash
###
 # @Author: eay
 # @Date: 2022-01-13 17:09:14
 # @LastEditors: eay 1015714710@qq.com
 # @Autor: Seven
 # @LastEditTime: 2023-03-29 14:17:14
 # @Description: 
### 
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# sed -i '$a src-git small8 https://github.com/kenzok8/small-package' feeds.conf.default
# sed -i '$a src-git small https://github.com/kenzok8/small' feeds.conf.default
sed -i '$a  src-git small8 https://github.com/kenzok8/small-package' feeds.conf.default
sed -i '$a src-git small https://github.com/kenzok8/small' feeds.conf.default

#sed -i '$a src-git darkmatter https://github.com/apollo-ng/luci-theme-darkmatter.git' feeds.conf.default
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argonnew

#ddns-go
git clone https://github.com/sirpdboy/luci-app-ddns-go.git package/ddns-go
#smartdns
#git clone https://github.com/pymumu/smartdns.git package/smartdns
#git clone https://github.com/pymumu/luci-app-smartdns.git package/luci-app-smartdns
