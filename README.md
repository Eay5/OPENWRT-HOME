# ImmortalWrt x86_64 高性能定制固件自动构建项目

[![ImmortalWrt](https://img.shields.io/badge/Source-ImmortalWrt%20Master-blue.svg)](https://github.com/immortalwrt/immortalwrt)
[![Kernel](https://img.shields.io/badge/Kernel-Linux%206.18-success.svg)](https://kernel.org/)
[![Arch](https://img.shields.io/badge/Arch-x86__64--v2%20(SSE4.2%2FAES--NI)-informational.svg)]()
[![Package Manager](https://img.shields.io/badge/Package%20Manager-APK%20(apk--tools)-orange.svg)](https://gitlab.alpinelinux.org/alpine/apk-tools)
[![Firewall](https://img.shields.io/badge/Firewall-Firewall4%20(nftables)-red.svg)](https://openwrt.org/docs/guide-user/firewall/firewall_configuration)

基于 [ImmortalWrt Master](https://github.com/immortalwrt/immortalwrt) 源码全量编译的新一代 **x86_64** 高性能路由固件。全面拥抱 **Linux 6.18 内核**、**Alpine APK (`apk-tools`)** 现代包管理与 **Firewall4 (`nftables`)** 网络架构，针对**主路由 / 旁路由双栖场景**、**网页秒开响应**、**万兆/多千兆满速下载**与**7×24 小时零断流长期稳定运行**进行了全链路深度调优。

---

## 📦 四大专属固件版本矩阵

本仓库通过 GitHub Actions 提供 **4 款定位清晰的专属固件变体**，每次构建均独立发布带完整编译时间戳与插件版本清单的 Release：

| 版本代号 | 工作流文件 | 默认后台 IP | 主机名 | 适用硬件与场景 | 核心代理 / 服务引擎与专属特性 |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **`6.18`** | `6.18-openwrt.yml` | `192.168.0.233` | `EAY` | **虚拟机 / 软路由通用版**<br>(Unraid / PVE / ESXi / Hyper-V) | **HomeProxy (Sing-box)** + **SmartDNS (6053)** + **Dnsmasq 2.93+**<br>内置全套虚拟化半虚拟化驱动 (Virtio-Net/Blk/SCSI/VMXNET3) 与主流 Intel/Realtek 2.5G/5G/10G 驱动。<br>📖 配套文档：[Unraid 虚拟机直通调优指南](UNRAID-VM-GUIDE.md) |
| **`6.18-physical`** | `6.18-physical-openwrt.yml` | `192.168.0.233` | `EAY` | **x86 物理机 / 工控机裸机直装版**<br>(Intel N100/N305/i3/i5 & AMD 平台) | **HomeProxy (Sing-box)** + **SmartDNS (6053)** + **Dnsmasq 2.93+**<br>补全 **Intel + AMD 双平台 CPU 微码**、**Intel i915 核显 GuC/HuC 固件**、**万兆网卡驱动 (ixgbe/i40e/igc/r8125/r8126/atlantic/mlx4/mlx5)**、`lm-sensors` 温度传感器、`smartmontools` 硬盘健康监控与多网口首启自动角色划分。 |
| **`6.18-honk`** | `6.18-honk-openwrt.yml` | `192.168.0.233` | `EAY` | **eBPF 内核态极速透明代理版**<br>(追求极致转发吞吐与超低延迟) | **HONK (eBPF + Doona 现代化 Web UI)** + **SmartDNS (6053)**<br>编译开启完整内核 **BTF (`CONFIG_DEBUG_INFO_BTF=y`)**、**BPF JIT** 与 **TC `cls_bpf`/`sch_ingress`**；跳过传统 Socket 栈直接在网卡 TC 层完成透明分流，形成 `本机/内网 -> Dnsmasq(53) -> HONK eBPF -> SmartDNS(6053)` 零污染闭环。 |
| **`6.18-lucky`** | `6.18-lucky-openwrt.yml` | `192.168.0.245` | `EAY-LUCKY` | **外网入站 / 反代 / STUN 穿透专属网关**<br>(独立旁路应用服务器) | **Lucky 大吉满血版** (DDNS / HTTPS 反向代理 / STUN 内网穿透 / WebDAV / 端口转发 / WOL)<br>彻底剔除科学代理、SmartDNS、SQM 等组件；独享 **100 万级 Conntrack 连接表**、**128MB TCP 套接字窗口**、**硬件 AES-NI/GCM 加密加速**与 **IPv6 原生双栈支持**。 |

---

## 📌 固件默认登录与网络参数

| 属性项 | `6.18` / `6.18-physical` / `6.18-honk` | `6.18-lucky` (Lucky 专属网关) |
| :--- | :--- | :--- |
| **LuCI 后台地址** | `http://192.168.0.233` | `http://192.168.0.245` |
| **默认主网关 / DNS** | `192.168.0.1`（主路由模式下自动切换为 WAN 口动态获取） | `192.168.0.1` |
| **登录用户名** | `root` | `root` |
| **登录密码** | **无密码**（首次登录直接留空回车即可） | **无密码**（首次登录直接留空回车即可） |
| **默认主题** | `Argon` (内置 `luci-app-argon-config` 主题设置插件) | `Argon` (内置 `luci-app-argon-config` 主题设置插件) |
| **包管理器** | `apk` (Alpine `apk-tools` 3.x) | `apk` (Alpine `apk-tools` 3.x) |

---

## 🚀 核心架构与全链路深度优化亮点

### 1. 主路由 / 旁路由双栖智能自适应架构
固件在首次启动及每次开机自检时（[`01-physical-net-role`](file:///c:/Users/eay/Desktop/project/OPENWRT-HOME/physical-files/etc/uci-defaults/01-physical-net-role)、[`98-custom-settings`](file:///c:/Users/eay/Desktop/project/OPENWRT-HOME/files/etc/uci-defaults/98-custom-settings)、[`99-system-performance`](file:///c:/Users/eay/Desktop/project/OPENWRT-HOME/files/etc/uci-defaults/99-system-performance)）会自动探测物理/虚拟网口数量与 `network.wan` 拓扑，实现**零手动干预的双栖无缝切换**：
- **多网口主路由模式 (`eth0` + `eth1`...)**：
  - 自动划分 `eth0` 为 LAN、`eth1` 为 WAN（其余多余网口自动并入 `br-lan` 充当交换机口），自动开启 LAN 口 DHCP 服务。
  - **消除内网二次 NAT 损耗**：自动关闭 LAN Zone 的 `masq` 与 `mtu_fix`，仅在 WAN Zone 开启 NAT 伪装与 MSS 钳制，并开启网桥二层硬件直通（`bridge-nf-call-iptables=0`），让局域网 NAS/PC 互传跑满物理线速。
  - **PPPoE 拨号专属加速**：自动将 `pppoe-wan` 虚拟接口发送队列从内核默认的 `3` 扩容至 **`4096`**，彻底根治千兆/万兆宽带 PPPoE 高并发上传时的队列溢出丢包；同时仅在主路由模式下激活 `miniupnpd` 自动端口映射。
- **单网口旁路由模式 (单臂 `eth0`)**：
  - 自动关闭 LAN DHCP Server（防止与主路由抢答 DHCP），自动在 LAN Zone 开启 `masq=1` 与 `mtu_fix=1`，并全接口强制锁死 `send_redirects=0` / `accept_redirects=0` 与宽松反向路径校验 (`rp_filter=2`)，彻底消灭旁路由 ICMP 重定向风暴与非对称路由丢包。

### 2. 零等待 DNS 加速矩阵与“刚刷机未配节点不断网”保护
- **SmartDNS (端口 `6053`) + Dnsmasq 2.93+ (端口 `53`) 双层架构**：
  - **0ms 乐观缓存响应**：开启 `serve-expired` 与 `prefetch-domain`，配備 **262,144 条**纯内存持久化缓存 (`/tmp/smartdns.cache`)；网页常用域名解析耗时稳定在 **`0ms` ~ `1ms`**。
  - **非标端口防抢答 (`speed-check-mode tcp:443,tcp:80,ping`)**：上游全部采用 DoH / DoT / TCP 及非 53 端口，绕开国内运营商对 UDP 53 的抢答劫持，取真实握手最快 IP 返回。
  - **刚刷机 / 停用代理自动兜底不断网**：当刚刷入固件尚未填写节点或手动停用 HomeProxy 时，启动脚本自动为 Dnsmasq 注入 `223.5.5.5` 与 `119.29.29.29` 保底上游；一旦启用 HomeProxy 或 HONK，立即无缝接管至 `127.0.0.1#6053` 分流矩阵，彻底解决传统固件刷机后“未配节点无法解析任何国内域名”的痛点。

### 3. 精准分流与防断流传输层黑科技
- **精准拦截海外代理 QUIC，100% 释放国内 HTTP/3 极速体验**：
  - 移除防火墙层面一刀切封杀全局 UDP 443 的粗暴规则，仅在 HomeProxy 出站路由规则 (`routing_rule`) 中精准拦截走海外代理的 QUIC 流量（强制海外回退平滑稳定的 TCP/TLS，根治 YouTube/Google 间歇卡顿），同时让国内 B 站、淘宝、抖音、微信视频号满速跑在 HTTP/3 QUIC 协议上。
- **TCP 首包窗口扩充 (`initcwnd=32` / `initrwnd=32`) 与 256KB 初始缓冲**：
  - 自动将主路由/旁路由默认网关路由的初始拥塞窗口与接收窗口从内核默认的 `10` 提升至 **`32`**（首包无需等待 RTT 慢启动即可直传约 46KB 数据），配合 `rmem_default=262144` / `wmem_default=262144`（256KB 默认 Socket 缓冲）与 **BBR + 被动 ECN (`tcp_ecn=2`) + DSACK**，实现网页图片与首屏 DOM 瞬间加载。
- **BIG TCP 与网卡全功能硬件卸载**：
  - 开启 IPv4 GRO/GSO 64KB 大包聚合 (`gso_max_size=65536`, `gro_max_size=65536`)，强制开启网卡 `TSO`、`GSO`、`GRO`、`SG` 与 Linux 6.x **`rx-udp-gro-forwarding`**，大幅压降 Hysteria2 / VLESS / WireGuard 等高吞吐转发时的 CPU 软中断负载。

### 4. 硬件级防掉线与 7×24 小时免重启自愈机制
- **杜绝 2.5G/万兆网卡间歇性断流**：自动关闭所有物理网口的 **EEE (Energy Efficient Ethernet 节能以太网)**，强制将 PCIe 总线 **ASPM 电源策略锁死为 `performance`**，并禁用延迟大于 `30us` 的深度 CPU C-States 睡眠，从根源上消除 Intel i225/i226 与 Realtek RTL8125/8126 网卡因节能唤醒不及时导致的“假死掉包”与微秒级抖动。
- **核心守护进程“免死金牌”**：开机与每晚定时为 `dnsmasq`、`smartdns`、`sing-box`、`honk`、`lucky`、`uhttpd` 赋予 **`oom_score_adj = -900`** 最高防杀保护与 **`renice -n -5`** 高 CPU 调度优先级。
- **根分区 `noatime` 免写放大与凌晨 4:00 内存自愈**：自动为 `/` 与 `/overlay` 挂载 `noatime` 保护 SSD/U 盘寿命；每日凌晨 4:00 自动检测内存水位，安全回收碎片化 PageCache/Slab 并清理失效 Conntrack 幽灵连接。

### 5. 全插件与分流规则库实时追踪上游最新正式版
每次触发 GitHub Actions 编译时，工作流会自动通过 GitHub API 与 Git 远端拉取各核心组件的最新正式版源码与规则集，并在 Release 页面生成组件版本清单：
- **编译器指令集加速**：全固件 C/C++ 采用 `-O2 -march=x86-64-v2 -mtune=generic` 编译，Golang 升级至 **Go 27.x** 并开启 **`GOAMD64=v2`**（硬件原生启用 SSE4.2 / POPCNT / AES-NI 指令集）。
- **核心组件动态追新**：`Sing-box` (最新正式版 Release)、`HomeProxy` (master HEAD)、`HONK + Doona` (`kenzok8/openwrt-honk` HEAD)、`SmartDNS` (`PikuZheng/smartdns` HEAD)、`Lucky` (`gdy666/luci-app-lucky` 最新正式版 Tag)、`Dnsmasq-full` (`2.93+`)、`Argon 主题 + 主题配置插件` (`jerrykuku` v3.x) 以及 `sing-geoip` / `sing-geosite` / `v2ray-rules-dat` 最新分流规则库。

---

## 📊 内置全链路运行诊断与脱敏日志一键导出系统 (AI 协同调优)

固件内置了专为日常排障与 **AI 协同性能调优**设计的全链路诊断系统。当路由器运行一段时间后，您可以随时一键导出完整运行状态与全插件日志发给 AI 进行针对性优化分析：

### 方式一：LuCI 网页后台一键下载 / 复制（推荐）
1. 登录路由器后台，进入顶部菜单 **系统 (System) -> 运行诊断与日志导出**；
2. 页面会自动实时采集当前系统的 **15 大核心模块数据**；
3. 点击 **📥 一键下载诊断日志 (`.txt`)** 保存到本地，或点击 **📋 一键复制全文** 直接粘贴发送给 AI。

### 方式二：SSH 终端命令行一键生成
在 SSH 终端中直接执行：
```bash
openwrt-diag
```
脚本会自动生成完整诊断报告并保存至 `/tmp/openwrt-diag-latest.txt`。

### 诊断报告包含的 15 大采集模块与隐私保护
- **系统与网络底层 (模块 1~7)**：CPU 频率/P-State/C-States/硬件温度、内存 Slab/句柄/进程 Top 排行、主/旁路由拓扑与路由表 `initcwnd` 检查、网卡硬件丢包 (`/proc/net/dev`)/BIG TCP/卸载状态、多核软中断 (`softirqs` / `softnet_stat` / `RPS/XPS`)、BBR/Conntrack 统计、核心守护进程 OOM/优先级与 **7 大国内外域名实时 DNS 解析耗时对比 (`53` vs `6053`)**。
- **全插件专项深度日志 (模块 8~15)**：自动触发 `Dnsmasq` 缓存命中率统计 (`SIGUSR1`)，并完整采集 **SmartDNS**、**HomeProxy**、**Sing-box**、**HONK (eBPF TC 钩子与 BTF 状态)**、**Lucky 大吉**、**MiniUPnPd**、**Firewall4 (`nftables`)**、**PPPoE/netifd 拨号记录**以及 **dmesg / logread** 告警日志。
- **🔒 自动隐私脱敏保护**：导出时通过内置 POSIX 脱敏过滤器自动将宽带账号密码、代理节点服务器 IP/域名、UUID、公私钥、Token 以及机场订阅链接替换为 `***REDACTED***`，同时完整保留公共 DNS 与性能计数，安全无忧。

---

## 🛠️ 编译与固件获取指引

### 1. 直接下载预编译固件
进入本仓库的 **[Releases](../../releases)** 页面，根据您的硬件环境选择对应标签（`6.18-*`、`6.18-physical-*`、`6.18-honk-*`、`6.18-lucky-*`）下载：
- `*-generic-squashfs-combined-efi.img.gz`：UEFI 启动固件镜像（推荐，支持写盘工具直刷或虚拟机导入）
- `*-generic-squashfs-combined.img.gz`：传统 Legacy BIOS 启动固件镜像
- `*.qcow2` / `*.vmdk` / `*.vhdx`：KVM (PVE/Unraid)、ESXi、Hyper-V 专用虚拟磁盘镜像

### 2. 使用 GitHub Actions 自定义编译
1. **Fork** 本仓库到您的 GitHub 账号下；
2. 点击仓库顶部的 **Actions** 标签页；
3. 在左侧工作流列表中选择您需要的固件变体：
   - **Build 6.18 ImmortalWrt**（虚拟机/软路由通用版）
   - **Build 6.18 ImmortalWrt (x86 Physical + Intel/RTL 2.5G)**（物理机裸机满血版）
   - **Build 6.18 ImmortalWrt HONK**（HONK eBPF + Doona 极速透明代理版）
   - **Build 6.18 ImmortalWrt LUCKY**（Lucky 反代/穿透专属网关版）
4. 点击右侧 **Run workflow** 按钮即可启动全自动云端编译（内置 `ccache` 编译器签名缓存与工具链二级缓存加速）。

---

## 💡 常用 APK 包管理命令速查

本固件采用新一代 **Alpine APK (`apk-tools`)** 替代了传统的 `opkg`，毫秒级索引更新且绝不卡死。在 SSH 终端中常用命令如下：

```bash
# 1. 更新软件源索引
apk update

# 2. 搜索软件源中的可用包
apk search <keyword>

# 3. 在线安装软件包
apk add <package_name>

# 4. 安装本地上传的 .apk 软件包
apk add --allow-untrusted /tmp/package_name.apk

# 5. 卸载软件包
apk del <package_name>

# 6. 列出当前已安装的所有软件包（可配合 grep 过滤）
apk list -I
apk list -I | grep luci-app

# 7. 查看指定软件包的详细版本与依赖信息
apk info <package_name>
```

---

## 🔗 核心上游致谢

* **基础固件源码**：[immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt)
* **HomeProxy 透明代理**：[immortalwrt/homeproxy](https://github.com/immortalwrt/homeproxy) & [SagerNet/sing-box](https://github.com/SagerNet/sing-box)
* **HONK eBPF 透明代理**：[kenzok8/openwrt-honk](https://github.com/kenzok8/openwrt-honk)
* **SmartDNS 本地加速引擎**：[PikuZheng/smartdns](https://github.com/PikuZheng/smartdns) & [pymumu/smartdns](https://github.com/pymumu/smartdns)
* **Lucky 大吉反代与穿透**：[gdy666/luci-app-lucky](https://github.com/gdy666/luci-app-lucky)
* **Argon 主题套件**：[jerrykuku/luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon) & [jerrykuku/luci-app-argon-config](https://github.com/jerrykuku/luci-app-argon-config)
* **Golang 构建工具链**：[sbwml/packages_lang_golang](https://github.com/sbwml/packages_lang_golang)

由衷感谢所有为 OpenWrt、ImmortalWrt、Linux 内核以及开源社区无私奉献的开发者们！
