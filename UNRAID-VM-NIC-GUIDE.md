# Unraid 虚拟机 OpenWrt 网卡高性能配置指南

本文档专门整理 **Unraid KVM 虚拟机**部署 OpenWrt / ImmortalWrt 时的网卡配置避坑要点、满血多队列 XML 配置片段与完整模板，确保解锁 **VirtIO 多队列 + 1024 环形缓冲 + TSO/GSO/SG 硬件卸载**。

---

## 一、核心避坑对照（必看）

| 配置项 | ❌ 错误 / 限速配置 | ✅ 正确 / 满血配置 | 差异与影响 |
| :--- | :--- | :--- | :--- |
| **网络桥接 (`source bridge`)** | `virbr0` | **`br0`** | `virbr0` 是隔离 NAT 网段 (`192.168.122.x`)，局域网无法 `ping` 通或访问后台；必须使用 `br0` 接入物理局域网。 |
| **网卡型号 (`model type`)** | `virtio-net` | **`virtio`** | `virtio-net` 在 Unraid 中会降级为兼容模式，导致网卡被锁死在 **1 队列、`RX/TX=256`、`TSO/GSO/SG` 全部关闭**；改为 `virtio` 才能激活满血 `vhost-net` 硬件卸载与多队列。 |
| **多队列与缓冲 (`driver`)** | 未配置（默认 1 队列 / 256） | **`name='vhost' queues='N' rx_queue_size='1024' tx_queue_size='1024'`** | 将 `queues` 设为与虚拟机 vCPU 核心数一致（例如 4 核写 `4`，12 核写 `12`），配合固件内置的 RSS/XPS 1:1 绑核彻底消除单核软中断瓶颈。 |

---

## 二、VirtIO 满血网卡 XML 配置片段

在 Unraid 虚拟机编辑页右上角切换到 **XML View**，找到 `<interface type='bridge'>` 节点，按以下格式配置（保留你原有的 `<mac address='...'/>` 与 `<address .../>`）：

```xml
    <interface type='bridge'>
      <mac address='52:54:00:04:24:47'/>
      <source bridge='br0'/>
      <model type='virtio'/>
      <driver name='vhost' queues='12' rx_queue_size='1024' tx_queue_size='1024'/>
      <boot order='2'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </interface>
```

> 💡 **提示**：
> - `queues='12'` 应与 `<vcpu>` 分配的逻辑核心数保持一致（如分配 4 核则填 `queues='4'`，分配 8 核则填 `queues='8'`）。
> - 若给 OpenWrt 分配了**双虚拟网口（主路由 LAN + WAN）**，两个 `<interface>` 均需按上述方式设置为 `virtio` + `vhost` 多队列。

---

## 三、完整 Unraid 高性能 VM XML 参考模板（12 vCPU 示例）

本模板同步包含：
- **网卡**：`br0` + `virtio` 12 队列 + `1024` 收发缓冲
- **磁盘**：独立 `iothreads` + `cache='writeback' io='threads' discard='unmap'`（兼容 Unraid 阵列与缓存盘路径）
- **CPU / 时钟**：`host-passthrough` 指令集透传 + 原生 `tsc` 时钟
- **低延迟与加解密**：禁用 `memballoon` 防止内存动态回收引发丢包 + 新增 `virtio-rng` 加速 TLS 握手

```xml
<?xml version='1.0' encoding='UTF-8'?>
<domain type='kvm'>
  <name>OP-Honk</name>
  <uuid>2b2daa76-a3fd-f643-701d-c84cbcb5ff41</uuid>
  <metadata>
    <vmtemplate xmlns="unraid" name="Linux" iconold="linux.png" icon="linux.png" os="linux" webui="" storage="default"/>
  </metadata>
  <memory unit='KiB'>1572864</memory>
  <currentMemory unit='KiB'>1572864</currentMemory>
  <memoryBacking>
    <nosharepages/>
  </memoryBacking>
  <vcpu placement='static'>12</vcpu>
  <iothreads>1</iothreads>
  <cputune>
    <vcpupin vcpu='0' cpuset='0'/>
    <vcpupin vcpu='1' cpuset='1'/>
    <vcpupin vcpu='2' cpuset='2'/>
    <vcpupin vcpu='3' cpuset='3'/>
    <vcpupin vcpu='4' cpuset='4'/>
    <vcpupin vcpu='5' cpuset='5'/>
    <vcpupin vcpu='6' cpuset='6'/>
    <vcpupin vcpu='7' cpuset='7'/>
    <vcpupin vcpu='8' cpuset='8'/>
    <vcpupin vcpu='9' cpuset='9'/>
    <vcpupin vcpu='10' cpuset='10'/>
    <vcpupin vcpu='11' cpuset='11'/>
    <iothreadpin iothread='1' cpuset='0-11'/>
  </cputune>
  <resource>
    <partition>/machine</partition>
  </resource>
  <os>
    <type arch='x86_64' machine='pc-i440fx-10.2'>hvm</type>
    <loader readonly='yes' type='pflash' format='raw'>/usr/share/qemu/ovmf-x64/OVMF_CODE-pure-efi.fd</loader>
    <nvram format='raw'>/etc/libvirt/qemu/nvram/2b2daa76-a3fd-f643-701d-c84cbcb5ff41_VARS-pure-efi.fd</nvram>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='host-passthrough' check='none' migratable='on'>
    <topology sockets='1' dies='1' clusters='1' cores='6' threads='2'/>
    <cache mode='passthrough'/>
  </cpu>
  <clock offset='utc'>
    <timer name='hpet' present='no'/>
    <timer name='hypervclock' present='no'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='tsc' present='yes' mode='native'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/local/sbin/qemu</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='raw' cache='writeback' io='threads' discard='unmap' iothread='1'/>
      <source file='/mnt/disk2/ios/ImmortalWrt-6.18-HONK-20261119-0952-x86-64-ext4-combined-efi.img/ImmortalWrt-6.18-HONK-20261119-0952-x86-64-ext4-combined-efi.img'/>
      <target dev='hdc' bus='virtio'/>
      <serial>vdisk1</serial>
      <boot order='1'/>
      <alias name='virtio-disk2'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </disk>
    <controller type='pci' index='0' model='pci-root'>
      <alias name='pci.0'/>
    </controller>
    <controller type='virtio-serial' index='0'>
      <alias name='virtio-serial0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </controller>
    <controller type='usb' index='0' model='ich9-ehci1'>
      <alias name='usb'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x7'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci1'>
      <alias name='usb'/>
      <master startport='0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0' multifunction='on'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci2'>
      <alias name='usb'/>
      <master startport='2'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x1'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci3'>
      <alias name='usb'/>
      <master startport='4'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x2'/>
    </controller>
    <interface type='bridge'>
      <mac address='52:54:00:04:24:47'/>
      <source bridge='br0'/>
      <model type='virtio'/>
      <driver name='vhost' queues='12' rx_queue_size='1024' tx_queue_size='1024'/>
      <boot order='2'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </interface>
    <serial type='pty'>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
      <alias name='serial0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
      <alias name='channel0'/>
      <address type='virtio-serial' controller='0' bus='0' port='1'/>
    </channel>
    <input type='tablet' bus='usb'>
      <alias name='input0'/>
      <address type='usb' bus='0' port='1'/>
    </input>
    <input type='mouse' bus='ps2'>
      <alias name='input1'/>
    </input>
    <input type='keyboard' bus='ps2'>
      <alias name='input2'/>
    </input>
    <graphics type='vnc' port='5903' autoport='yes' websocket='5700' listen='0.0.0.0' sharePolicy='ignore'>
      <listen type='address' address='0.0.0.0'/>
    </graphics>
    <audio id='1' type='none'/>
    <video>
      <model type='qxl' ram='65536' vram='16384' vgamem='16384' heads='1' primary='yes'/>
      <alias name='video0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x1e' function='0x0'/>
    </video>
    <rng model='virtio'>
      <backend model='random'>/dev/urandom</backend>
      <alias name='rng0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </rng>
    <memballoon model='none'/>
  </devices>
</domain>
```

---

## 四、开机后验证满血生效命令

启动虚拟机后，在 OpenWrt SSH 终端中执行以下 3 条命令检查：

```sh
# 1. 验证多队列已生效（应显示 numtxqueues 12 numrxqueues 12）
ip -d link show dev eth0 | grep -E 'numtxqueues|numrxqueues'

# 2. 验证硬件卸载已全开（scatter-gather / tso / gso / gro / rx-udp-gro-forwarding 均为 on）
ethtool -k eth0 | grep -E 'scatter-gather|tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload|rx-udp-gro-forwarding'

# 3. 验证收发环形缓冲已扩容至 1024（RX: 1024, TX: 1024）
ethtool -g eth0
```
