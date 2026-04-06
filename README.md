# Alpine Linux - Magisk 模块

在 Android 设备上以 chroot 方式运行 Alpine Linux 的 Magisk 模块。

## 功能特性

- 自动下载 rootfs，自动检测架构
- 服务管理，统一使用 service 命令
- 预设常用应用，一键添加服务
- 开机自启动
- 一键配置 SSH
- 存储挂载

## 系统要求

- Android 5.0+
- Magisk v20.4+
- root 权限
- 约 100MB 可用空间

## 安装方法

1. 下载最新版本模块包
2. Magisk Manager 中选择"从本地安装"
3. 重启设备

## 快速开始

```bash
alpine download
alpine start
alpine service add openclaw
alpine shell
```

## 完整命令

### 容器管理

| 命令 | 说明 |
|------|------|
| `alpine start` | 启动 Alpine |
| `alpine stop` | 停止 Alpine |
| `alpine restart` | 重启 Alpine |
| `alpine status` | 查看状态 |
| `alpine shell` | 进入 shell |
| `alpine exec <命令>` | 执行命令 |

### rootfs 管理

| 命令 | 说明 |
|------|------|
| `alpine download` | 自动下载安装 |
| `alpine download aarch64` | 指定架构下载 |
| `alpine install <文件>` | 从本地安装 |
| `alpine mirror tuna` | 设置镜像源 |

### 服务管理

| 命令 | 说明 |
|------|------|
| `alpine service add openclaw` | 添加预设应用 |
| `alpine service add myapp "命令"` | 添加自定义服务 |
| `alpine service list` | 查看服务列表 |
| `alpine service start openclaw` | 启动服务 |
| `alpine service stop openclaw` | 停止服务 |
| `alpine service status openclaw` | 查看状态 |
| `alpine service enable openclaw` | 启用自启动 |
| `alpine service disable openclaw` | 禁用自启动 |
| `alpine service logs openclaw` | 查看日志 |
| `alpine service rm openclaw` | 删除服务 |

**预设应用：**

| 应用 | 命令 |
|------|------|
| openclaw | `openclaw gateway --port 18789` |
| sshd | `/usr/sbin/sshd` |
| nginx | `nginx` |
| redis | `redis-server` |
| mysql | `mysqld` |
| postgres | `postgres` |

### SSH 配置

| 命令 | 说明 |
|------|------|
| `alpine ssh` | 一键配置 SSH（端口22，密码123456） |
| `alpine ssh 22 mypassword` | 指定端口和密码 |
| `alpine ssh start` | 启动 SSH |
| `alpine ssh stop` | 停止 SSH |
| `alpine ssh status` | 查看状态 |

### 软件安装

| 命令 | 说明 | 安装内容 |
|------|------|----------|
| `alpine install-pkg` | 安装基础工具 | bash, coreutils, vim, curl, wget |
| `alpine install-pkg dev` | 安装开发环境 | bash, vim, curl, git, python3, nodejs, gcc |
| `alpine install-pkg net` | 安装网络工具 | bash, vim, curl, openssh, openssl |
| `alpine install-pkg tools` | 安装常用工具 | bash, vim, curl, htop, tree, rsync |
| `alpine install-pkg all` | 安装全部软件 | bash, vim, curl, git, python3, nodejs, gcc, openssh, htop, tree, rsync |
| `alpine install-pkg <包名>` | 安装指定软件包 | 自定义 |

## 使用示例

### 添加 OpenClaw 服务

```bash
alpine service add openclaw
alpine service start openclaw
alpine service status openclaw
```

### 添加自定义服务

```bash
alpine service add myapp "/usr/local/bin/myapp --config /etc/myapp.conf"
alpine service start myapp
```

## 目录结构

| 路径 | 说明 |
|------|------|
| `/data/alpine_linux/rootfs` | Alpine rootfs |
| `/data/alpine_linux/services` | 服务配置文件 |
| `/mnt/sdcard` | Android 存储（Alpine 内） |
| `/mnt/external_sd` | 外置 SD 卡（Alpine 内） |
| `/mnt/android` | Android 系统根目录（Alpine 内） |

## 镜像源

| 名称 | 地址 |
|------|------|
| tuna | 清华大学（默认） |
| ustc | 中科大 |
| official | 官方源 |

## 许可证

MIT License

## 项目地址

| 平台 | 地址 |
|------|------|
| GitHub | https://github.com/chuanglizhe/alpine-linux-magisk |
| Gitee | https://gitee.com/chuanglizhe/alpine-linux-magisk |
