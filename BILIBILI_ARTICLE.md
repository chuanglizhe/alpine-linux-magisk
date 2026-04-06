# 在 Android 手机上运行完整 Linux 系统！Alpine Linux Magisk 模块使用教程

> 想在 Android 手机上运行 Linux？不需要虚拟机，不需要特殊内核，一个 Magisk 模块就能搞定！

## 一、这是什么？

Alpine Linux Magisk 模块是一个可以在 Android 设备上运行完整 Alpine Linux 系统的工具。

通过 chroot 技术，让你在 Android 手机上拥有一个独立的 Linux 环境。你可以：

- 运行 Linux 命令和脚本
- 安装开发环境（Python、Node.js、Git 等）
- 部署服务（Nginx、MySQL、Redis 等）
- 远程 SSH 访问手机

**核心特性：**

- 一键安装 - 自动下载 rootfs，自动检测 CPU 架构
- 服务管理 - 统一的 service 命令管理后台服务
- 开机自启 - 服务随 Alpine 自动启动
- SSH 支持 - 一键配置 SSH 远程访问
- 存储访问 - 自动挂载 Android 存储，文件互通

---

## 二、准备工作

### 系统要求

- Android 5.0 及以上
- Magisk v20.4 及以上
- root 权限
- 至少 100MB 可用空间

### 下载模块

- GitHub：github.com/chuanglizhe/alpine-linux-magisk
- Gitee：gitee.com/chuanglizhe1/alpine-linux-magisk

---

## 三、安装模块

### 步骤 1：安装 Magisk 模块

1. 打开 Magisk Manager
2. 点击「模块」
3. 点击「从本地安装」
4. 选择下载的模块包
5. 安装完成后重启设备

### 步骤 2：验证安装

重启后，打开终端（Termux 或 ADB Shell），执行：

```
alpine help
```

如果显示帮助信息，说明安装成功！

---

## 四、快速开始

### 4.1 下载并启动 Alpine

```
# 自动下载 rootfs（首次使用）
alpine download

# 启动 Alpine Linux
alpine start

# 进入 Alpine shell
alpine shell
```

### 4.2 查看运行状态

```
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
========================================
```

### 4.3 安装常用软件

```
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

### 5.2 添加和管理服务

```
# 添加预设服务
alpine service add openclaw

# 添加自定义服务
alpine service add myapp "/usr/local/bin/myapp --config /etc/myapp.conf"

# 查看所有服务
alpine service list

# 启动/停止服务
alpine service start openclaw
alpine service stop openclaw

# 查看服务状态和日志
alpine service status openclaw
alpine service logs openclaw
```

### 5.3 开机自启

```
# 启用开机自启
alpine service enable openclaw

# 禁用开机自启
alpine service disable openclaw
```

---

## 六、SSH 远程访问

### 6.1 一键配置 SSH

```
# 默认配置：端口 22，密码 123456
alpine ssh

# 自定义配置：端口 8022，密码 mypassword
alpine ssh 8022 mypassword
```

### 6.2 连接 SSH

```
# 从同一网络的电脑连接
ssh root@<手机IP> -p 22

# 默认密码：123456
```

### 6.3 管理 SSH 服务

```
alpine ssh start     # 启动
alpine ssh stop      # 停止
alpine ssh restart   # 重启
alpine ssh status    # 查看状态
```

---

## 七、进阶使用

### 7.1 手动安装 rootfs

如果自动下载失败，可以手动下载 rootfs：

1. 访问 alpinelinux.org/downloads
2. 下载对应架构的 minirootfs
3. 将文件放到手机存储
4. 执行安装：

```
alpine install /sdcard/Download/alpine-minirootfs-xxx.tar.gz
```

### 7.2 设置镜像源

使用国内镜像加速软件安装：

```
alpine mirror tuna    # 清华镜像（默认）
alpine mirror ustc    # 中科大镜像
```

### 7.3 访问 Android 文件

Alpine 容器内已自动挂载 Android 存储：

| Alpine 路径 | 对应 Android 路径 |
|-------------|------------------|
| /mnt/sdcard | /sdcard (内部存储) |
| /mnt/external_sd | 外置 SD 卡 |
| /mnt/android | / (系统根目录，只读) |

---

## 八、常见问题

**Q: 提示 "rootfs 不存在"？**

A: 执行 `alpine download` 下载安装

**Q: 下载 rootfs 失败？**

A: 检查网络，或手动下载后使用 `alpine install` 安装

**Q: 服务无法启动？**

A:
1. 确认 Alpine 已启动：`alpine status`
2. 查看服务日志：`alpine service logs <服务名>`

**Q: SSH 无法连接？**

A:
1. 确认 SSH 服务运行：`alpine ssh status`
2. 确认手机和电脑在同一网络

---

## 九、项目地址

- GitHub：github.com/chuanglizhe/alpine-linux-magisk
- Gitee：gitee.com/chuanglizhe1/alpine-linux-magisk

---

## 总结

Alpine Linux Magisk 模块让你在 Android 手机上轻松运行 Linux 环境，无需虚拟机，无需折腾。适合：

- 移动开发：随时随地写代码
- 服务器部署：手机秒变服务器
- Linux 学习：在手机上学习 Linux 命令
- 自动化脚本：后台运行各种脚本

觉得有用的话，给个 Star 支持一下吧！

---

#Android #Linux #Magisk #教程 #技术分享
