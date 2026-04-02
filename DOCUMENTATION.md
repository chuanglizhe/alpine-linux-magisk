# Alpine Linux Magisk 模块 - 完整技术文档

![Alpine Linux](https://img.shields.io/badge/Alpine%20Linux-Magisk%20Module-0D597F?style=for-the-badge&logo=alpine-linux&logoColor=white)

![License](https://img.shields.io/badge/License-MIT-green?style=flat)
![Platform](https://img.shields.io/badge/Platform-Android-orange?style=flat)
![Arch](https://img.shields.io/badge/Arch-aarch64%20%7C%20armv7%20%7C%20x86_64-blue?style=flat)

> **项目定位**：在 Android 设备上以 chroot 方式运行 Alpine Linux 的 Magisk 模块，提供完整的 Linux 容器体验。

---

## ⚠️ 免责声明

```
* 您的设备保修将失效
* 使用此模块导致的任何问题，作者不承担责任
* 您需自行承担风险
* 本项目开源，您可以 fork 或重写，但请不要责怪作者
* Alpine Linux 是 Alpine Linux Development Team 的注册商标，本项目与其无关联
```

---

## 📋 项目概述

### 与标准 Alpine 的关系

| 方面 | 标准 Alpine | Alpine Magisk 模块 |
|-----|------------|-------------------|
| **运行环境** | 独立系统/虚拟机 | Android chroot 容器 |
| **内核** | Alpine 内核 | Android 内核 |
| **权限模型** | 完整 root | Android root + Magisk |
| **存储访问** | 独立分区 | 挂载 Android 存储 |
| **服务管理** | OpenRC | 自定义 service 命令 |
| **网络** | 独立网络栈 | 共享 Android 网络 |

### 核心特性

| 功能类别 | 具体能力 |
|---------|---------|
| **rootfs 管理** | 自动下载 Alpine rootfs；自动检测 CPU 架构；支持多版本；多镜像源 |
| **容器运行** | chroot 容器执行；自动挂载系统目录；网络自动配置；存储自动挂载 |
| **服务管理** | systemd 风格配置；预设常用应用；开机自启；日志查看 |
| **SSH 服务** | 一键配置 OpenSSH；自定义端口密码；密钥认证支持 |
| **软件管理** | apk 包管理；预设软件包组；镜像源配置 |

---

## 🏗️ 架构设计

### 系统架构

```
┌─────────────────────────────────────────────────────────┐
│                    Android 系统                          │
│                    (Host OS)                             │
├─────────────────────────────────────────────────────────┤
│                   Magisk 框架                            │
│              (Systemless Root)                           │
├─────────────────────────────────────────────────────────┤
│                  Alpine Linux                            │
│                  (chroot 容器)                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │  /bin   /sbin   /usr    /lib    /etc            │   │
│  │  Alpine Linux 用户空间                           │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  /mnt/sdcard     Android 内部存储               │   │
│  │  /mnt/external_sd 外置 SD 卡                    │   │
│  │  /mnt/android    Android 系统根目录 (只读)      │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 模块文件结构

```
/data/adb/modules/alpine_linux/
├── module.prop          # 模块属性
├── common.sh            # 核心函数库
├── service.sh           # 开机启动脚本
├── post-fs-data.sh      # 初始化脚本
├── uninstall.sh         # 卸载脚本
└── system/bin/
    ├── alpine           # 主控制命令
    ├── alpine-shell     # 快捷进入 shell
    └── alpine-exec      # 快捷执行命令

/data/alpine_linux/
├── rootfs/              # Alpine Linux rootfs
├── services/            # 服务配置目录
│   ├── *.service        # 服务配置文件
│   └── *.enabled        # 启用标记文件
├── alpine.pid           # 运行时 PID 文件
└── alpine.log           # 运行日志
```

---

## ⚙️ 配置系统

### 全局变量定义

```bash
# 路径配置
R="/data/alpine_linux"           # 模块数据目录
RF="$R/rootfs"                   # rootfs 路径
PID="$R/alpine.pid"              # PID 文件
SVC="$R/services"                # 服务目录
LOG="$R/alpine.log"              # 日志文件

# 颜色定义
Rd='\033[0;31m'                  # 红色 (错误)
Gr='\033[0;32m'                  # 绿色 (成功)
Yw='\033[1;33m'                  # 黄色 (警告)
Nc='\033[0m'                     # 重置颜色
```

### rootfs 检查机制

```bash
ck() {
    [ -d "$RF" ] || return 1
    for d in bin dev etc lib root usr sbin var tmp; do
        [ -d "$RF/$d" ] || return 1
    done
    [ -x "$RF/bin/sh" ] || [ -L "$RF/bin/sh" ]
}
```

| 检查项 | 说明 | 失败处理 |
|-------|------|---------|
| 目录存在 | `$RF` 是否存在 | return 1 |
| 子目录检查 | bin, dev, etc, lib, root, usr, sbin, var, tmp | return 1 |
| shell 检查 | /bin/sh 可执行或符号链接 | return 1 |

---

## 📦 依赖和系统要求

### 系统要求

| 要求 | 最低版本 | 推荐版本 |
|-----|---------|---------|
| Android | 5.0 (API 21) | 10.0+ |
| Magisk | v20.4 | v24.0+ |
| 存储空间 | 100 MB | 500 MB+ |
| 架构 | armv7, aarch64, x86_64 | - |

### 内置工具依赖

模块运行需要以下 Android 系统工具：

| 工具 | 用途 | 必需性 |
|-----|------|--------|
| `mount` | 挂载文件系统 | ✅ 必需 |
| `chroot` | 切换根目录 | ✅ 必需 |
| `tar` | 解压 rootfs | ✅ 必需 |
| `wget`/`curl` | 下载 rootfs | ✅ 必需（任一） |
| `unzip` | 模块升级 | ✅ 必需 |

---

## 🛡️ 安全机制

### 挂载隔离

```
Alpine 容器挂载点:
├── /proc      → proc (独立)
├── /sys       → sysfs (独立)
├── /dev       → bind from Android
├── /dev/pts   → devpts (独立)
├── /tmp       → tmpfs (独立)
└── /run       → tmpfs (独立)
```

### Android 系统保护

- `/mnt/android` 以只读方式挂载
- 防止误操作导致 Android 系统损坏

### 权限分离

- 通过 Magisk root 权限运行
- 不修改系统分区 (systemless)
- 数据存储在 `/data/alpine_linux/`

---

## 📚 命令参考

### 容器管理命令

| 命令 | 说明 | 示例 |
|-----|------|------|
| `alpine start` | 启动 Alpine 容器 | `alpine start` |
| `alpine stop` | 停止 Alpine 容器 | `alpine stop` |
| `alpine restart` | 重启容器 | `alpine restart` |
| `alpine status` | 查看运行状态 | `alpine status` |
| `alpine shell` | 进入 Alpine shell | `alpine shell` |
| `alpine exec <cmd>` | 执行命令 | `alpine exec "apk update"` |

### rootfs 管理命令

| 命令 | 说明 | 参数 |
|-----|------|------|
| `alpine download` | 自动下载安装 | `[架构] [版本] [镜像源]` |
| `alpine install` | 从本地安装 | `<文件路径>` |
| `alpine mirror` | 设置镜像源 | `<tuna\|ustc\|official>` |

### 服务管理命令

| 命令 | 说明 | 示例 |
|-----|------|------|
| `service add` | 添加服务 | `alpine service add openclaw` |
| `service list` | 列出服务 | `alpine service list` |
| `service start` | 启动服务 | `alpine service start nginx` |
| `service stop` | 停止服务 | `alpine service stop nginx` |
| `service status` | 查看状态 | `alpine service status sshd` |
| `service enable` | 启用自启 | `alpine service enable nginx` |
| `service disable` | 禁用自启 | `alpine service disable nginx` |
| `service logs` | 查看日志 | `alpine service logs openclaw` |
| `service rm` | 删除服务 | `alpine service rm myapp` |

### SSH 管理命令

| 命令 | 说明 | 示例 |
|-----|------|------|
| `alpine ssh` | 一键配置 SSH | `alpine ssh 22 mypassword` |
| `alpine ssh start` | 启动 SSH | `alpine ssh start` |
| `alpine ssh stop` | 停止 SSH | `alpine ssh stop` |
| `alpine ssh status` | 查看状态 | `alpine ssh status` |

### 软件安装命令

| 命令 | 安装内容 |
|-----|---------|
| `alpine install-pkg` | bash, coreutils, vim, curl, wget |
| `alpine install-pkg dev` | bash, vim, curl, git, python3, nodejs, gcc |
| `alpine install-pkg net` | bash, vim, curl, openssh, openssl |
| `alpine install-pkg tools` | bash, vim, curl, htop, tree, rsync |
| `alpine install-pkg all` | 全部上述软件包 |
| `alpine install-pkg <包名>` | 自定义软件包 |

---

## 🎯 执行流程

### 模块启动流程

```
Android 启动
    │
    ├── post-fs-data.sh
    │       └── 创建必要目录
    │       └── 设置 PATH 环境变量
    │
    └── service.sh (系统启动完成后)
            │
            ├── 等待 boot_completed
            │
            ├── 检查 rootfs
            │       └── 失败 → 退出
            │
            ├── alpine_start()
            │       ├── 检查 rootfs
            │       ├── 挂载系统目录
            │       ├── 配置网络
            │       ├── 挂载存储
            │       └── 启动已启用服务
            │
            └── 完成
```

### 服务配置格式

```ini
[Unit]
Description=服务名称

[Service]
ExecStart=启动命令
```

---

## 🖥️ 支持的架构

| 架构别名 | 识别标识 | rootfs 下载 |
|---------|---------|------------|
| aarch64 | aarch64, arm64-v8a | alpine-minirootfs-*-aarch64.tar.gz |
| armv7 | armv7*, armeabi-v7a | alpine-minirootfs-*-armv7.tar.gz |
| armhf | arm*, armeabi | alpine-minirootfs-*-armhf.tar.gz |
| x86_64 | x86_64, amd64 | alpine-minirootfs-*-x86_64.tar.gz |
| x86 | x86, i686 | alpine-minirootfs-*-x86.tar.gz |

---

## 📁 镜像源配置

| 名称 | 地址 | 用途 |
|-----|------|------|
| tuna | mirrors.tuna.tsinghua.edu.cn | 清华大学镜像（默认） |
| ustc | mirrors.ustc.edu.cn | 中科大镜像 |
| official | dl-cdn.alpinelinux.org | 官方源 |

---

## 📝 使用示例

### 基础使用

```bash
# 下载并安装 rootfs
alpine download

# 启动 Alpine
alpine start

# 进入 shell
alpine shell

# 安装软件
alpine install-pkg dev
```

### 服务管理

```bash
# 添加 OpenClaw 服务
alpine service add openclaw

# 添加自定义服务
alpine service add myapp "/path/to/app --option value"

# 启动服务
alpine service start openclaw

# 查看服务状态
alpine service status openclaw

# 查看日志
alpine service logs openclaw
```

### SSH 配置

```bash
# 一键配置 SSH（默认：端口22，密码123456）
alpine ssh

# 自定义配置
alpine ssh 8022 mypassword

# 连接
ssh root@localhost -p 22
```

---

## 🔧 故障排除

### 常见问题

| 问题 | 可能原因 | 解决方案 |
|-----|---------|---------|
| rootfs 不存在 | 未安装 rootfs | 运行 `alpine download` |
| 挂载失败 | 权限不足 | 检查 Magisk root 权限 |
| 网络不通 | DNS 配置问题 | 检查 `/etc/resolv.conf` |
| 服务不启动 | 配置错误 | 检查 `.service` 文件 |

### 日志查看

```bash
# 查看模块日志
alpine log

# 查看服务日志
alpine service logs <服务名>
```

---

## 📜 许可证

```
MIT License

Copyright (c) 2024-2025 chuanglizhe

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🔗 相关链接

- **GitHub 仓库**：https://github.com/chuanglizhe/alpine-linux-magisk
- **Alpine Linux 官网**：https://alpinelinux.org
- **Magisk 官网**：https://topjohnwu.github.io/Magisk

---

<p align="center">「简洁、高效、稳定」</p>
