# 🚀 Unraid 虚拟机部署 ImmortalWrt 最佳实践配置指南

本文档专门针对在 **Unraid KVM 虚拟机** 中运行本固件（ImmortalWrt）提供完整的调优与设置指南，重点针对 **网卡直通（PCIe Passthrough）**、**低延迟** 与 **满血吞吐** 场景进行深度优化。

---

## 📑 目录
1. [固件镜像准备](#一固件镜像准备)
2. [Unraid 虚拟机参数设置（图形界面）](#二unraid-虚拟机参数设置图形界面)
3. [PCIe 网卡直通配置流程](#三pcie-网卡直通配置流程)
4. [混合组网：VirtIO 虚拟网卡多队列优化（可选）](#四混合组网virtio-虚拟网卡多队列优化可选)
5. [QEMU XML 深度性能调优配置](#五qemu-xml-深度性能调优配置)
6. [固件开机后性能自检清单](#六固件开机后性能自检清单)

---

## 一、固件镜像准备

1. **解压固件**：
   下载 GitHub Actions 编译出的固件压缩包（例如 `immortalwrt-x86-64-generic-ext4-combined-efi.img.gz`），解压得到 `.img` 文件。
2. **上传至 Unraid**：
   将解压后的 `.img` 镜像上传到 Unraid 的缓存盘虚拟机目录，例如：
   ```bash
   /mnt/user/domains/ImmortalWrt/immortalwrt.img
   ```
3. **（可选）扩容虚拟磁盘空间**：
   如果希望为路由系统预留更大空间（例如 10GB），在 Unraid 终端中执行：
   ```bash
   qemu-img resize /mnt/user/domains/ImmortalWrt/immortalwrt.img 10G
   ```

---

## 二、Unraid 虚拟机参数设置（图形界面）

在 Unraid **VMs -> Add VM -> Linux** 中按以下推荐参数配置：

| 配置项 | 推荐设置 | 说明与优化原理 |
| :--- | :--- | :--- |
| **Name** | `ImmortalWrt` | 虚拟机名称 |
| **CPU Mode** | **`Host-Passthrough`** | **【核心必选】** 直接透传物理 CPU 的 AES-NI、AVX2 指令集，代理加解密性能提升数倍 |
| **Logical CPUs** | 勾选 **2 ~ 4 个核心** | 分配 2~4 个物理 CPU 核心 |
| **Initial Memory** | `1024 MB` 或 `2048 MB` | 运行 MosDNS、SmartDNS 持久化缓存 1~2G 即可满足 |
| **Max Memory** | `1024 MB` 或 `2048 MB` | 保持与初始内存一致，避免内存气球动态调节引入网络丢包 |
| **Machine** | **`Q35`**（如 `pc-q35-7.1` 或最新） | PCIe 设备直通兼容性最佳 |
| **BIOS** | **`OVMF (UEFI)`** | 现代 UEFI 固件引导，与本固件 EFI 镜像完美配合 |
| **Primary vDisk Location** | **`Manual`** -> 指向上述 `.img` 路径 | 填入 `/mnt/user/domains/ImmortalWrt/immortalwrt.img` |
| **Primary vDisk Bus** | **`VirtIO`** 或 **`SATA`** | 本固件内置 VirtIO 块设备驱动，推荐 VirtIO |
| **Primary vDisk Type** | **`raw`** | RAW 格式比 qcow2 延迟更低、吞吐更高 |

---

## 三、PCIe 网卡直通配置流程

若准备将独立网卡（如 Intel i225/i226 2.5G、Intel i210/i350 千兆、Realtek 8125 或万兆网卡）完全直通给虚拟机：

### 1. 开启 IOMMU 与 PCIe ACS 覆盖（若单口无法独立勾选）
1. 进入 Unraid **Settings -> VM Manager**。
2. 将 **PCIe ACS override** 设置为 **`Both`** 或 **`Downstream`**。
3. 将 **VFIO allow unsafe interrupts** 设置为 **`Yes`**。
4. 点击 Apply 并**重启 Unraid 宿主机**。

### 2. 绑定网卡到 VFIO
1. 进入 Unraid **Tools -> System Devices**。
2. 找到要直通的物理网卡，勾选前面的复选框（例如 `[8086:15f3] Ethernet Controller I225-V`）。
3. 点击底部 **`BIND SELECTED TO VFIO AT BOOT`** 并重启生效。

### 3. 在虚拟机中添加直通网卡
1. 编辑 ImmortalWrt 虚拟机。
2. 在底部的 **Other PCI Devices** 列表中，勾选刚刚绑定的直通物理网卡。
3. 点击 **Update** 保存。

---

## 四、混合组网：VirtIO 虚拟网卡多队列优化（可选）

> **典型场景**：直通 1 个物理网口做 WAN 口；LAN 侧使用 Unraid 的 `br0`（VirtIO 桥接网卡），方便 Unraid 宿主机及其他 Docker 容器共享软路由网络。

若使用了虚拟网卡（`virtio-net`），必须开启**多队列（Multi-Queue）**，防止所有网络中断挤在单个 CPU 核心上：

1. 编辑虚拟机，右上角切换到 **XML View**。
2. 找到虚拟网卡节点 `<interface type='bridge'>`。
3. 在 `<model type='virtio'/>` 下方添加 `<driver>` 多队列参数：
   ```xml
   <interface type='bridge'>
     <mac address='52:54:00:xx:xx:xx'/>
     <source bridge='br0'/>
     <model type='virtio'/>
     <driver name='vhost' queues='2' rx_queue_size='1024' tx_queue_size='1024'/>
   </interface>
   ```
   > 💡 注：`queues` 数值建议设置为分配给该 VM 的 vCPU 核心数（例如分配了 2 个核心就设为 `2`）。

---

## 五、QEMU XML 深度性能调优配置

在虚拟机配置页面右上角点击 **XML View**，加入以下关键调优片段：

```xml
  <!-- 1. CPU 宿主机直通与指令集无损透传 -->
  <cpu mode='host-passthrough' check='none' migratable='on'/>

  <!-- 2. TSC 高精度原生时钟（消除虚拟机时钟中断开销） -->
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
    <timer name='tsc' present='yes' mode='native'/>
  </clock>

  <!-- 3. 透传宿主机硬件随机数发生器（加速 SSL/TLS 握手） -->
  <devices>
    <rng model='virtio'>
      <backend model='random'>/dev/urandom</backend>
    </rng>
  </devices>
```

---

## 六、Unraid 宿主机 CPU 核心隔离（彻底消除网络抖动）

1. 进入 Unraid **Settings -> CPU Pinning**。
2. 展开 **CPU Isolations (Isolate CPUs)**。
3. 勾选分配给 ImmortalWrt 的物理核心（例如 Core 2、Core 3）。
4. **作用**：禁止 Unraid 宿主机、Array 校验盘任务、qBittorrent/Plex 等高负载 Docker 抢占这几个核心，保证路由数据包转发**绝对低延迟、零丢包**。

---

## 七、固件开机后性能自检清单

固件启动后，登录 OpenWrt 终端（SSH 或 Web 终端）验证调优生效情况：

1. **检查直通物理网卡驱动识别**：
   ```bash
   lspci -k
   ethtool eth0
   ```
2. **检查 CPU AES-NI 硬件加速生效**：
   ```bash
   grep -E 'aes|avx' /proc/cpuinfo
   ```
3. **检查多网卡中断均衡（irqbalance）运行状态**：
   ```bash
   /etc/init.d/irqbalance status
   cat /proc/interrupts
   ```
4. **确认防火墙硬件/软件流加速（Flow Offloading）已启用**：
   - 登录 LuCI 后台：**网络 -> 防火墙**。
   - 确保 **软件流量分流 (Software flow offloading)** 为勾选状态。
