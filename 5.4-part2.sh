#ip
sed -i 's/192\.168\.1\.1/192.168.0.133/g' package/base-files/files/bin/config_generate

# 编译5.10
sed -i 's/KERNEL_PATCHVER:=*.*/KERNEL_PATCHVER:=5.4/g' target/linux/x86/Makefile
#2. Clear the login password
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings
#4.an-theme
#取消bootstrap为默认主题：
sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' feeds/luci/collections/luci/Makefile
#name
sed -i "/option hostname/s/'LEDE'/'EAY'/" package/base-files/files/etc/config/system

sed -i "s/hostname='LEDE'/hostname='EAY'/g" package/base-files/files/bin/config_generate

