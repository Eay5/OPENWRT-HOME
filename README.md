# ImmortalWrt x86_64 自动构建项目

[![ImmortalWrt](https://img.shields.io/badge/Source-ImmortalWrt%20Master-blue.svg)](https://github.com/immortalwrt/immortalwrt)
[![Kernel](https://img.shields.io/badge/Kernel-6.18-green.svg)](https://kernel.org/)
[![Package Manager](https://img.shields.io/badge/Package%20Manager-APK%20(apk--tools)-orange.svg)](https://gitlab.alpinelinux.org/alpine/apk-tools)
[![Firewall](https://img.shields.io/badge/Firewall-Firewall4%20(nftables)-red.svg)](https://openwrt.org/docs/guide-user/firewall/firewall_configuration)
[![GitHub Actions](https://img.shields.io/badge/Actions-CI%2FCD%20Ready-brightgreen.svg)]()

基于 [ImmortalWrt Master](https://github.com/immortalwrt/immortalwrt) 源码全量构建的新一代 x86_64 路由固件。全面拥抱 **Alpine APK (apk-tools)** 包管理与 **Firewall4 (nftables)** 现代网络架构。

---

## 🌟 核心特性与架构升级

1. **新一代 APK 包管理系统**
   - 彻底替代传统老旧的 `opkg/ipk`，采用 Alpine Linux 标准的 `apk-tools` 引擎。
   - 毫秒级索引更新、极速原子安装、极低内存开销，彻底杜绝安装插件时 OOM 卡死问题。

2. **现代化网络栈与防火墙**
   - **Linux 6.18** 最新内核驱动支持。
   - **Firewall4 (nftables)** 替代传统 iptables，转发性能与 NAT 吞吐大幅提升。
   - **dnsmasq-full (nftset)** 强力分流，与透明代理无缝协同。

3. **开箱即用的深度性能调优**
   - **BBR / Hybla / Scalable** TCP 拥塞控制算法预置。
   - **网卡 RPS / XPS 多队列绑定** 与软中断均衡分流。
   - **网卡 UDP GRO (Generic Receive Offload)** 开启，大幅降低高负载代理转发时的 CPU 占用。
   - **CPU Governor & EPP** 性能档位锁定。

4. **双重 DNS 智能分流栈**
   - 预置 **SmartDNS**（端口 6053）+ **MosDNS v5** 双方案，支持一键切换脚本（`dns-profile-smartdns` / `dns-profile-mosdns`）。
   - IPv6 LAN 侧 DNS 智能通告闭环，防止 IPv6 泄露与旁路绕过。

---

## 📌 固件默认信息

| 属性 | 默认值 |
| :--- | :--- |
| **后台管理地址** | `192.168.0.133` |
| **默认主机名** | `EAY` |
| **登录用户名** | `root` |
| **登录密码** | `无`（首次登录直接回车即可） |
| **默认主题** | `Argon` (jerrykuku) |
| **包管理工具** | `apk` (apk-tools 3.x) |

---

## 📦 构建版本说明

本仓库通过 GitHub Actions 提供两种针对性优化的构建变体：

| 版本代号 | 目标场景 | 包含核心驱动 / 特性 |
| :--- | :--- | :--- |
| **`6.18`** | **虚拟化 / 软路由**<br>(PVE / ESXi / Hyper-V / Unraid) | Virtio (Net/Blk/SCSI/Balloon/RNG/Console)、VMXNET3、Intel (e1000/e1000e/igb/igc/ixgbe)、Realtek (r8169/r8125)<br>📖 [Unraid 虚拟机直通调优指南](file:///c:/Users/eay/Desktop/OPENWRT-HOME/UNRAID-VM-GUIDE.md) |
| **`6.18-physical`** | **物理机 / 工控机直装** | Intel 全系网卡 (e1000/e1000e/igb/igc 2.5G)、Realtek (r8169/r8125 2.5G)、Intel CPU 微码、`autocore` 硬件监控、`smartmontools` + `hd-idle` 硬盘休眠与健康管理、首启多网口智能角色自动划分 |

---

## 🛠️ 插件与上游来源

* **基础固件源码**：[ImmortalWrt](https://github.com/immortalwrt/immortalwrt)
* **科学代理套件**：[SSR-Plus (fw876/helloworld)](https://github.com/fw876/helloworld)
* **分流 DNS 服务**：[MosDNS v5 (sbwml)](https://github.com/sbwml/luci-app-mosdns)
* **本地加速 DNS**：[SmartDNS (PikuZheng)](https://github.com/PikuZheng/smartdns)
* **LuCI 主题套件**：[Argon Theme (jerrykuku)](https://github.com/jerrykuku/luci-theme-argon)
* **Golang 构建环境**：[Go 26.x (sbwml)](https://github.com/sbwml/packages_lang_golang)
* **Actions 构建脚本**：[P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)

---

## 💡 常用 APK 命令速查（管理固件）

固件开机后，在 SSH 终端中请使用 `apk` 命令代替过去的 `opkg`：

```bash
# 1. 更新软件源索引
apk update

# 2. 安装软件包
apk add <package_name>

# 3. 安装本地下载的 .apk 安装包
apk add --allow-untrusted /tmp/package_name.apk

# 4. 卸载软件包
apk del <package_name>

# 5. 查询已安装的所有软件包（或按关键词过滤）
apk list -I
apk list -I | grep luci-app

# 6. 搜索软件源中的可用包
apk search <keyword>

# 7. 查看软件包详细信息
apk info <package_name>
```

---

## 🚀 编译指引

1. Fork 本仓库并进入 GitHub 仓库页面；
2. 导航至 **Actions** 标签页；
3. 选择 **Fast ImmortalWrt Build (Release Toolchain Cache)** 工作流；
4. 点击右侧 **Run workflow** 下拉菜单，选择目标版本（`6.18` 或 `6.18-physical`），点击运行即可全自动输出固件。

---

## ❤️ 致谢

由衷感谢所有为 OpenWrt、ImmortalWrt、LEDE 以及开源社区无私奉献的大佬们！
