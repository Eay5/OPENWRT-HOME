# ImmortalWrt x86_64 自动构建项目

[![ImmortalWrt](https://img.shields.io/badge/Source-ImmortalWrt%20Master-blue.svg)](https://github.com/immortalwrt/immortalwrt)
[![Kernel](https://img.shields.io/badge/Kernel-Linux%206.18-success.svg)](https://kernel.org/)
[![Package Manager](https://img.shields.io/badge/Package%20Manager-APK%20(apk--tools)-orange.svg)](https://gitlab.alpinelinux.org/alpine/apk-tools)
[![Firewall](https://img.shields.io/badge/Firewall-Firewall4%20(nftables)-red.svg)](https://openwrt.org/docs/guide-user/firewall/firewall_configuration)

基于 [ImmortalWrt Master](https://github.com/immortalwrt/immortalwrt) 源码构建的新一代 **x86_64** 高性能路由固件，采用 **Linux 6.18 内核**、**Alpine APK (`apk-tools`)** 包管理与 **Firewall4 (`nftables`)** 网络架构。

---

## 📌 默认信息

| 属性 | 默认值 |
| :--- | :--- |
| **后台地址** | `192.168.0.233`（`6.18-lucky` 版本为 `192.168.0.245`） |
| **默认主机名** | `EAY`（`6.18-lucky` 版本为 `EAY-LUCKY`） |
| **用户名 / 密码** | `root` / **无密码**（首次登录直接回车） |
| **默认主题** | `Argon`（含 `luci-app-argon-config` 主题设置） |
| **包管理器** | `apk` (`apk-tools` 3.x) |

---

## 📦 固件版本说明

| 版本代号 | 目标场景 | 核心特性与组件 |
| :--- | :--- | :--- |
| **`6.18`** | **虚拟机 / 软路由**<br>(Unraid / PVE / ESXi / Hyper-V) | **HomeProxy (Sing-box)** + **SmartDNS (6053)** + **Dnsmasq 2.93+**<br>含全套虚拟化驱动 (Virtio / VMXNET3) 及主流 2.5G/5G/10G 网卡驱动。<br>📖 [Unraid 虚拟机直通调优指南](UNRAID-VM-GUIDE.md) |
| **`6.18-physical`** | **x86 物理机 / 工控机直装** | **HomeProxy (Sing-box)** + **SmartDNS (6053)** + **Dnsmasq 2.93+**<br>含 Intel/AMD 双微码、i915 核显固件、全系 2.5G/5G/万兆物理网卡驱动、温度与硬盘健康监控、多网口自动划分 WAN/LAN。 |
| **`6.18-honk`** | **eBPF 内核态透明代理** | **HONK (eBPF + Doona Web UI)** + **SmartDNS (6053)**<br>开启内核 BTF 与 TC eBPF 硬件级挂载分流，极致吞吐与超低延迟。 |
| **`6.18-lucky`** | **反代 / STUN 穿透专属网关** | **Lucky 大吉满血版**（默认 IP `192.168.0.245`）<br>专为外网入站服务打造，剔除代理与多余组件，支持 100 万级高并发连接、AES-NI 硬件加速与 IPv6 双栈穿透。 |

---

## 🌟 核心特性

1. **主路由 / 旁路由双栖自适应**：自动识别单/多网口与 WAN 拓扑，自动切换 DHCP、NAT 伪装、MSS 钳制、网桥二层直通与 UPnP，并针对 PPPoE 拨号队列深度优化。
2. **极速 DNS 与透明分流**：SmartDNS (6053) 乐观缓存实现 0ms 级响应；精准拦截海外代理 QUIC 并完整保留国内 HTTP/3 加速；刷机未配节点时自动兜底保障国内正常联网。
3. **Linux 6.18 深度性能调优**：全固件启用 `x86-64-v2` 与 `GOAMD64=v2` 指令集加速；内置 TCP BBR、首包窗口加速 (`initcwnd=32`)、BIG TCP、网卡多队列 RPS/XPS 均衡与 UDP GRO 硬件卸载。
4. **7×24 小时防断流稳定保护**：自动禁用网卡 EEE 节能与 PCIe 休眠防断流，核心守护进程内置 OOM 防杀保护与每日凌晨内存自动整理。
5. **全组件实时追踪上游最新正式版**：每次编译自动拉取 Sing-box、HomeProxy、HONK、SmartDNS、Lucky、Argon 与 GeoIP/GeoSite 最新正式版源码及规则库。

---

## 💡 常用 APK 命令

```bash
apk update                                  # 更新软件源索引
apk search <keyword>                        # 搜索软件包
apk add <package_name>                      # 在线安装软件包
apk add --allow-untrusted /tmp/xxx.apk      # 安装本地 .apk 包
apk del <package_name>                      # 卸载软件包
apk list -I                                 # 查看已安装软件包
```

---

## 🚀 编译指引

1. **Fork** 本仓库并进入 **Actions** 页面；
2. 在左侧选择对应工作流（`Build 6.18 ImmortalWrt` / `Physical` / `HONK` / `LUCKY`）；
3. 点击右侧 **Run workflow** 即可全自动编译并发布至 Releases。

---

## ❤️ 致谢

感谢 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)、[Sing-box](https://github.com/SagerNet/sing-box)、[SmartDNS](https://github.com/PikuZheng/smartdns)、[HONK](https://github.com/kenzok8/openwrt-honk)、[Lucky](https://github.com/gdy666/luci-app-lucky)、[Argon](https://github.com/jerrykuku/luci-theme-argon) 及所有开源社区贡献者！
