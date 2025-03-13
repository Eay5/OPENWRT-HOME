name: Build 6.12-OpenWrt

on:
  repository_dispatch:
  workflow_dispatch:
    inputs:
      ssh:
        description: "SSH connection to Actions"
        required: false
        default: "false"
  schedule:
    - cron: 0 19 * * *  # 每天 19:00 UTC（即 Asia/Shanghai 的 03:00）
  watch:
    types: [started]

env:
  REPO_URL: https://github.com/coolsnowwolf/lede
  REPO_BRANCH: master
  FEEDS_CONF: feeds.conf.default
  CONFIG_FILE: 6.12.config
  DIY_P1_SH: 6.12-part1.sh
  DIY_P2_SH: 6.12-part2.sh
  UPLOAD_BIN_DIR: true
  UPLOAD_FIRMWARE: true
  UPLOAD_COWTRANSFER: true
  UPLOAD_WETRANSFER: true
  UPLOAD_RELEASE: true
  TZ: Asia/Shanghai

jobs:
  build:
    runs-on: ubuntu-22.04  # 使用 Ubuntu 22.04
    steps:
      # 检查项目分支并获取代码
      - name: 检查项目分支
        uses: actions/checkout@v4

      # 检查自定义文件是否存在
      - name: 检查自定义配置文件
        run: |
          ls -l $GITHUB_WORKSPACE/
          [ -f $CONFIG_FILE ] && echo "✅ $CONFIG_FILE 存在" || echo "❌ $CONFIG_FILE 不存在"
          [ -f $DIY_P1_SH ] && echo "✅ $DIY_P1_SH 存在" || echo "❌ $DIY_P1_SH 不存在"
          [ -f $DIY_P2_SH ] && echo "✅ $DIY_P2_SH 存在" || echo "❌ $DIY_P2_SH 不存在"

      # 清理更多空间
      - name: 清理更多空间
        run: |
          sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc
          df -hT

      # 安装编译环境
      - name: 安装编译环境
        env:
          DEBIAN_FRONTEND: noninteractive
        run: |
          sudo bash -c 'cat > /etc/apt/sources.list << EOF
          deb http://archive.ubuntu.com/ubuntu jammy main universe multiverse restricted
          deb http://archive.ubuntu.com/ubuntu jammy-updates main universe multiverse restricted
          deb http://archive.ubuntu.com/ubuntu jammy-security main universe multiverse restricted
          EOF'
          sudo apt-get update
          sudo apt-get install -y libc6-i386 gettext-base gcc g++ make ccache cmake \
            device-tree-compiler binutils bison flex zlib1g-dev libssl-dev libtool \
            ack antlr3 asciidoc autoconf automake autopoint bzip2 curl gawk \
            gcc-multilib g++-multilib gettext git gperf haveged help2man intltool \
            libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev \
            libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
            lrzsz msmtp ninja-build p7zip p7zip-full patch pkgconf python3 \
            python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools \
            subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd
          sudo apt-get autoremove -y
          sudo apt-get clean
          sudo apt-get check
          sudo -E timedatectl set-timezone "Asia/Shanghai"
          sudo mkdir -p /workdir
          sudo chown $USER:$GROUPS /workdir

      # 下载固件源码
      - name: 下载固件源码
        working-directory: /workdir
        run: |
          df -hT $PWD
          git clone $REPO_URL -b $REPO_BRANCH openwrt
          ln -sf /workdir/openwrt $GITHUB_WORKSPACE/openwrt

      # 清理旧的构建目录
      - name: 清理旧的构建目录
        run: |
          rm -rf openwrt/staging_dir openwrt/build_dir

      # 加载自定义设置并验证配置
      - name: 加载自定义设置
        run: |
          [ -e $FEEDS_CONF ] && mv $FEEDS_CONF openwrt/feeds.conf.default
          chmod +x $DIY_P1_SH
          cd openwrt
          $GITHUB_WORKSPACE/$DIY_P1_SH
          [ -e $CONFIG_FILE ] && mv $CONFIG_FILE openwrt/.config
          echo "Checking target device in .config:"
          cat openwrt/.config | grep '^CONFIG_TARGET.*DEVICE.*=y' || echo "Warning: No target device found in .config"

      # 下载插件
      - name: 下载插件
        run: |
          cd openwrt
          ./scripts/feeds update -a

      # 读取插件
      - name: 读取插件
        run: |
          cd openwrt
          ./scripts/feeds install -a

      # 清理 Golang host 构建缓存
      - name: 清理 Golang host 构建缓存
        run: |
          cd openwrt
          rm -rf build_dir/hostpkg/go-1.24.0
          rm -rf dl/go1.20.6.linux-amd64.tar.gz dl/go1.24.0.src.tar.gz

      # 下载并安装工具链
      - name: 下载并安装工具链
        run: |
          cd openwrt
          # 检查并替换默认的 Go bootstrap 版本为最新版 1.24.1
          GO_BOOTSTRAP_VERSION="1.24.1"
          GO_BOOTSTRAP_URL="https://dl.google.com/go/go${GO_BOOTSTRAP_VERSION}.linux-amd64.tar.gz"
          GO_BOOTSTRAP_HASH="76f2c4a92e293cf2d4df8690a94514e1a6f6f5b784e8216cb683961c76bd437c"
          if [ -f "dl/go1.20.6.linux-amd64.tar.gz" ]; then
            echo "Replacing Go 1.20.6 with Go ${GO_BOOTSTRAP_VERSION}"
            rm -f dl/go1.20.6.linux-amd64.tar.gz
            wget -P dl $GO_BOOTSTRAP_URL
            echo "$GO_BOOTSTRAP_HASH  dl/go${GO_BOOTSTRAP_VERSION}.linux-amd64.tar.gz" | sha256sum -c || exit 1
            ln -sf go${GO_BOOTSTRAP_VERSION}.linux-amd64.tar.gz dl/go1.20.6.linux-amd64.tar.gz
          fi
          make tools/install -j$(nproc) V=s 2>&1 | tee tools_install.log
          make toolchain/install -j$(nproc) V=s 2>&1 | tee toolchain_install.log

      # 上传工具链安装日志
      - name: 上传工具链安装日志
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: toolchain-install-logs
          path: |
            openwrt/tools_install.log
            openwrt/toolchain_install.log

      # 更改设置
      - name: 更改设置
        run: |
          [ -e files ] && mv files openwrt/files
          chmod +x $DIY_P2_SH
          cd openwrt
          $GITHUB_WORKSPACE/$DIY_P2_SH
          make defconfig  # 确保 .config 被应用

      # SSH 链接管理（可选）
      - name: SSH链接管理
        uses: P3TERX/ssh2actions@v1.0.0
        if: (github.event.inputs.ssh == 'true' && github.event.inputs.ssh != 'false') || contains(github.event.action, 'ssh')
        env:
          TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}

      # 下载安装包
      - name: 下载安装包
        id: package
        run: |
          cd openwrt
          make defconfig  # 再次确认配置，避免遗漏
          make download -j16 V=s 2>&1 | tee download.log
          find dl -size -1024c -exec ls -l {} \;
          find dl -size -1024c -exec rm -f {} \;

      # 检查磁盘空间
      - name: 检查磁盘空间
        run: |
          df -hT

      # 开始编译固件并检查输出
      - name: 开始编译固件
        id: compile
        run: |
          cd openwrt
          echo -e "Compiling with $(nproc) threads"
          make -j$(nproc) V=s 2>&1 | tee build.log || make -j1 V=s 2>&1 | tee -a build.log
          echo "Checking generated firmware:"
          ls -la bin/targets/*/* || echo "No firmware generated in bin/targets"
          echo "status=success" >> $GITHUB_ENV
          grep '^CONFIG_TARGET.*DEVICE.*=y' .config | sed -r 's/.*DEVICE_(.*)=y/\1/' > DEVICE_NAME
          [ -s DEVICE_NAME ] && echo "DEVICE_NAME=_$(cat DEVICE_NAME)" >> $GITHUB_ENV
          echo "FILE_DATE=_$(date +"%Y%m%d%H%M")" >> $GITHUB_ENV

      # 上传构建日志
      - name: 上传构建日志
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: build-log
          path: openwrt/build.log

      # 获取内核版本号
      - name: 获取内核版本号
        if: env.status == 'success'
        run: |
          KERNEL_VERSION=$(grep 'LINUX_VERSION-6.12' openwrt/include/kernel-6.12 | cut -d' ' -f3)
          echo "KERNEL_VERSION_6_12=${KERNEL_VERSION}" >> $GITHUB_ENV

      # 查看磁盘使用情况
      - name: 查看磁盘使用情况
        if: (!cancelled())
        run: |
          df -hT

      # 上传 bin 压缩目录
      - name: 上传bin压缩目录
        uses: actions/upload-artifact@v4
        if: env.status == 'success' && env.UPLOAD_BIN_DIR == 'true'
        with:
          name: OpenWrt_bin${{ env.DEVICE_NAME }}${{ env.FILE_DATE }}
          path: openwrt/bin

      # 整理编译好的固件
      - name: 整理编译好的固件
        id: organize
        if: env.UPLOAD_FIRMWARE == 'true' && !cancelled()
        run: |
          if ls openwrt/bin/targets/*/* >/dev/null 2>&1; then
            cd openwrt/bin/targets/*/*
            rm -rf packages
            echo "FIRMWARE=$PWD" >> $GITHUB_ENV
            echo "status=success" >> $GITHUB_ENV
          else
            echo "No firmware found in openwrt/bin/targets/"
            echo "status=failure" >> $GITHUB_ENV
          fi

      # 上传固件到github
      - name: 上传固件到github
        uses: actions/upload-artifact@v4
        if: env.status == 'success' && !cancelled()
        with:
          name: OpenWrt-6.12${{ env.DEVICE_NAME }}${{ env.FILE_DATE }}
          path: ${{ env.FIRMWARE }}

      # 创建 Release 标签
      - name: 创建 Release标签
        id: tag
        if: env.UPLOAD_RELEASE == 'true' && !cancelled()
        run: |
          echo "release_tag=$(date +"%Y.%m.%d-%H%M")" >> $GITHUB_ENV
          touch release.txt
          [ "$UPLOAD_COWTRANSFER" = true ] && echo "Cowtransfer enabled" >> release.txt
          echo "status=success" >> $GITHUB_ENV

      # 发布至 Release
      - name: 发布至 Release
        uses: softprops/action-gh-release@v1
        if: env.status == 'success' && !cancelled()
        env:
          GITHUB_TOKEN: ${{ secrets.RELEASE_TOKEN }}
        with:
          name: OpenWrt 6.12${{ env.KERNEL_VERSION_6_12}}-X86-64_${{ env.FILE_DATE }}
          tag_name: ${{ env.release_tag }}
          body_path: release.txt
          files: ${{ env.FIRMWARE }}/*

      # 删除工作流运行
      - name: 删除工作流运行
        uses: GitRML/delete-workflow-runs@main
        with:
          retain_days: 1
          keep_minimum_runs: 3

      # 删除旧的Releases
      - name: 删除旧的Releases
        uses: dev-drprasad/delete-older-releases@master
        if: env.UPLOAD_RELEASE == 'true' && !cancelled()
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          keep_latest: 30
          delete_tags: true