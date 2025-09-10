# OpenWrt Passwall 编译指南

## 🎯 **修复说明**

已将所有失败版本（6.12、6.1、6.6、5.15、5.4）的配置从 `luci-app-ssr-plus` 切换到 `luci-app-passwall`，并按照 [kenzok8/small 仓库](https://github.com/kenzok8/small) 官方建议优化了构建脚本。

## 📋 **主要改动**

### **配置文件改动**
- ❌ **禁用**: `CONFIG_PACKAGE_luci-app-ssr-plus=n`
- ✅ **启用**: `CONFIG_PACKAGE_luci-app-passwall=y`
- 🔧 **保留**: 所有 Passwall 依赖包（shadowsocks、v2ray、xray、trojan等）

### **构建脚本优化**
- 🚀 **使用官方推荐的一键命令**
- 🧹 **删除重复包以防止插件冲突**
- 📦 **使用 kenzok8/golang 仓库**
- ⚡ **移除复杂的Go版本升级逻辑**

## 🛠️ **编译步骤**

### **步骤 1: 选择版本**
推荐按以下顺序测试：
1. **5.15** (最稳定，与成功的5.10最接近)
2. **6.1** (LTS版本，相对稳定)
3. **6.6** (较新但稳定)
4. **6.12** (最新版本)
5. **5.4** (较老版本)

### **步骤 2: 运行构建脚本**
```bash
# 例如编译 6.1 版本
chmod +x 6.1-part1.sh 6.1-part2.sh
./6.1-part1.sh
./6.1-part2.sh
```

### **步骤 3: 配置编译**
```bash
# 复制配置文件
cp 6.1.config .config

# 进入配置菜单
make menuconfig
```

### **步骤 4: 开始编译**
```bash
# 单线程编译（推荐首次编译）
make V=s

# 或多线程编译（适用于后续编译）
make -j$(nproc) V=s
```

## 🔍 **关键配置说明**

### **Passwall 相关包**
```bash
# 主程序
CONFIG_PACKAGE_luci-app-passwall=y

# 核心依赖
CONFIG_PACKAGE_shadowsocks-libev-ss-local=y
CONFIG_PACKAGE_shadowsocks-libev-ss-redir=y
CONFIG_PACKAGE_shadowsocksr-libev-ssr-local=y
CONFIG_PACKAGE_v2ray-core=y
CONFIG_PACKAGE_xray-core=y
CONFIG_PACKAGE_trojan-plus=y
CONFIG_PACKAGE_naiveproxy=y
# ... 等等
```

### **防火墙配置**
```bash
# 确保防火墙管理界面启用
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_iptables=y
CONFIG_PACKAGE_firewall4=n  # 禁用新版防火墙
```

## 📦 **Passwall vs SSR Plus+ 对比**

| 特性 | Passwall | SSR Plus+ |
|------|----------|-----------|
| **稳定性** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **功能丰富度** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **编译兼容性** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **更新频率** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **社区支持** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

## 🚨 **常见问题解决**

### **1. 编译失败**
```bash
# 清理后重新编译
make clean
make V=s
```

### **2. 依赖包冲突**
```bash
# 确保删除了重复包
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,sing*,smartdns}
./scripts/feeds install -a
```

### **3. Go版本问题**
- 使用 kenzok8/golang 仓库自动处理Go版本
- 不需要手动升级Go版本

## 📚 **参考资料**

- **kenzok8/small 仓库**: https://github.com/kenzok8/small
- **kenzok8/openwrt-packages**: https://github.com/kenzok8/openwrt-packages
- **官方使用说明**: 仓库 README 中的一键命令

## 🎉 **预期结果**

使用 Passwall 替代 SSR Plus+ 后，预期所有版本都能成功编译，因为：

1. **更好的兼容性**: Passwall 对不同内核版本的兼容性更好
2. **简化的依赖**: 避免了复杂的Go版本升级
3. **官方支持**: 按照 kenzok8/small 官方建议配置
4. **减少冲突**: 删除重复包避免编译冲突

## 📞 **支持**

如果编译仍然失败，请检查：
- [ ] 是否使用了正确的配置文件
- [ ] 是否运行了更新后的构建脚本
- [ ] 是否有网络连接问题影响包下载
- [ ] 编译环境是否满足要求
