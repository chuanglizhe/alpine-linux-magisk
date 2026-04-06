# Alpine Linux Magisk 模块使用教程

## 一、简介

Alpine Linux Magisk 模块是一个可以在 Android 设备上运行完整 Alpine Linux 系统的 Magisk 模块。通过 chroot 技术，让你在 Android 手机上拥有一个独立的 Linux 环境，无需折腾虚拟机，无需特殊内核支持。

### 核心特性

- **一键安装** - 自动下载 rootfs，自动检测 CPU 架构
- **服务管理** - 统一的 service 命令管理后台服务
- **开机自启** - 服务随 Alpine 自动启动
- **SSH 支持** - 一键配置 SSH 远程访问
- **存储访问** - 自动挂载 Android 存储，文件互通

---

## 二、准备工作

### 系统要求

| 项目 | 最低要求 | 推荐配置 |
|------|---------|---------|
| Android 版本 | 5.0+ | 10.0+ |
| Magisk 版本 | v20.4+ | v24.0+ |
| 存储空间 | 100 MB | 500 MB+ |
| CPU 架构 | armv7 / aarch64 / x86_64 | - |

### 下载模块

从以下地址下载最新版本：

- **GitHub**: https://github.com/chuanglizhe/alpine-linux-magisk
- **Gitee**: https://gitee.com/chuanglizhe1/alpine-linux-magisk

---

## 三、安装模块

### 步骤 1：安装 Magisk 模块

1. 打开 Magisk Manager
2. 点击"模块"
3. 点击"从本地安装"
4. 选择下载的 `alpine-linux-v1.3.1.zip`
5. 安装完成后重启设备

### 步骤 2：验证安装

重启后，打开终端（如 Termux 或 ADB Shell），执行：

```bash
alpine help
```

如果显示帮助信息，说明安装成功。

---

## 四、快速开始

### 4.1 下载并启动 Alpine

```bash
# 自动下载 rootfs（首次使用）
alpine download

# 启动 Alpine Linux
alpine start

# 进入 Alpine shell
alpine shell
```

### 4.2 查看运行状态

```bash
alpine status
```

输出示例：
```
========================================
 Alpine Linux 状态
========================================
状态: 运行中
路径: /data/alpine_linux/rootfs
ROOTFS: 已安装

挂载点:
  /proc: 已挂载
  /sys: 已挂载
  /dev: 已挂载
  /tmp: 已挂载
  /run: 已挂载
========================================
```

### 4.3 安装常用软件

```bash
# 安装基础工具（bash, vim, curl 等）
alpine install-pkg

# 安装开发环境（git, python3, nodejs, gcc 等）
alpine install-pkg dev

# 安装全部软件
alpine install-pkg all
```

---

## 五、服务管理

### 5.1 预设服务

模块内置了常用服务的预设配置：

| 服务名 | 说明 |
|--------|------|
| openclaw | OpenClaw 网关服务 |
| sshd | SSH 服务端 |
| nginx | Web 服务器 |
| redis | Redis 数据库 |
| mysql | MySQL 数据库 |
| postgres | PostgreSQL 数据库 |

### 5.2 添加服务

```bash
# 添加预设服务
alpine service add openclaw

# 添加自定义服务
alpine service add myapp "/usr/local/bin/myapp --config /etc/myapp.conf"
```

### 5.3 管理服务

```bash
# 查看所有服务
alpine service list

# 启动服务
alpine service start openclaw

# 停止服务
alpine service stop openclaw

# 查看服务状态
alpine service status openclaw

# 查看服务日志
alpine service logs openclaw

# 删除服务
alpine service rm openclaw
```

### 5.4 开机自启

```bash
# 启用开机自启
alpine service enable openclaw

# 禁用开机自启
alpine service disable openclaw
```

服务列表中带 `*` 号的表示已启用自启：
```
服务列表:
  openclaw *
  nginx
  sshd *
```

---

## 六、SSH 远程访问

### 6.1 一键配置 SSH

```bash
# 默认配置：端口 22，密码 123456
alpine ssh

# 自定义配置：端口 8022，密码 mypassword
alpine ssh 8022 mypassword
```

### 6.2 连接 SSH

```bash
# 从同一网络的电脑连接
ssh root@<手机IP> -p 22

# 默认密码：123456
```

### 6.3 管理 SSH 服务

```bash
# 启动 SSH
alpine ssh start

# 停止 SSH
alpine ssh stop

# 重启 SSH
alpine ssh restart

# 查看状态
alpine ssh status
```

---

## 七、进阶使用

### 7.1 手动安装 rootfs

如果自动下载失败，可以手动下载 rootfs：

1. 访问 https://alpinelinux.org/downloads
2. 下载对应架构的 minirootfs（如 `alpine-minirootfs-3.19.0-aarch64.tar.gz`）
3. 将文件放到手机存储
4. 执行安装：

```bash
alpine install /sdcard/Download/alpine-minirootfs-3.19.0-aarch64.tar.gz
```

### 7.2 设置镜像源

使用国内镜像加速软件安装：

```bash
# 清华镜像（默认）
alpine mirror tuna

# 中科大镜像
alpine mirror ustc

# 官方源
alpine mirror official
```

### 7.3 在 Alpine 内访问 Android 文件

Alpine 容器内已自动挂载 Android 存储：

| Alpine 路径 | 对应 Android 路径 |
|-------------|------------------|
| `/mnt/sdcard` | `/sdcard` (内部存储) |
| `/mnt/external_sd` | 外置 SD 卡 |
| `/mnt/android` | `/` (系统根目录，只读) |

示例：
```bash
# 在 Alpine 内访问 Android 下载目录
cd /mnt/sdcard/Download
ls

# 读取 Android 系统文件
cat /mnt/android/system/build.prop
```

### 7.4 在 Alpine 内执行命令

不进入 shell 直接执行命令：

```bash
# 更新软件包列表
alpine exec "apk update"

# 安装软件
alpine exec "apk add python3"

# 查看系统信息
alpine exec "uname -a"
```

---

## 八、常见问题

### Q1: 提示 "rootfs 不存在"

**原因**：未安装 rootfs

**解决**：执行 `alpine download` 下载安装

### Q2: 下载 rootfs 失败

**原因**：网络问题或架构不支持

**解决**：
1. 检查网络连接
2. 手动下载 rootfs 后使用 `alpine install` 安装

### Q3: 服务无法启动

**原因**：服务未安装或配置错误

**解决**：
1. 确认 Alpine 已启动：`alpine status`
2. 查看服务日志：`alpine service logs <服务名>`
3. 手动进入 shell 排查：`alpine shell`

### Q4: SSH 无法连接

**原因**：防火墙或 IP 问题

**解决**：
1. 确认 SSH 服务运行：`alpine ssh status`
2. 确认手机和电脑在同一网络
3. 检查手机防火墙设置

### Q5: 如何卸载模块

1. 打开 Magisk Manager
2. 找到 Alpine Linux 模块
3. 点击删除
4. 重启设备

---

## 九、目录结构

| 路径 | 说明 |
|------|------|
| `/data/alpine_linux/rootfs` | Alpine Linux 根文件系统 |
| `/data/alpine_linux/services` | 服务配置目录 |
| `/data/alpine_linux/alpine.log` | 运行日志 |
| `/data/adb/modules/alpine_linux` | 模块安装目录 |

---

## 十、相关链接

- **GitHub**: https://github.com/chuanglizhe/alpine-linux-magisk
- **Gitee**: https://gitee.com/chuanglizhe1/alpine-linux-magisk
- **Alpine Linux 官网**: https://alpinelinux.org
- **Magisk 官网**: https://topjohnwu.github.io/Magisk

---

## 十一、许可证

MIT License
