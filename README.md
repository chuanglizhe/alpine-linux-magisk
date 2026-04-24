# Alpine Linux - Magisk 模块

在 Android 设备上以 chroot 方式运行 Alpine Linux 的 Magisk 模块。

**版本：v1.3.2**

---

## 功能特性

- ✅ 自动下载 rootfs，自动检测架构
- ✅ 服务管理，统一使用 `service` 命令
- ✅ 预设常用应用，一键添加服务
- ✅ 开机自启动
- ✅ 一键配置 SSH
- ✅ 存储挂载（内部存储、外置SD卡）
- ✅ 多镜像源支持（清华、中科大、官方）

---

## 系统要求

| 项目 | 要求 |
|------|------|
| Android | 5.0+ |
| Magisk | v20.4+ |
| 权限 | root |
| 空间 | 约 100MB |

---

## 安装方法

### 方法一：直接安装（推荐）

1. 将 `alpine-linux` 目录打包为 zip
2. Magisk Manager → 模块 → 从本地安装
3. 重启设备

### 方法二：手动复制

```bash
# 在设备上执行
cp -r alpine-linux/* /data/adb/modules/alpine_linux/
chmod +x /data/adb/modules/alpine_linux/*.sh
chmod +x /data/adb/modules/alpine_linux/system/bin/alpine
reboot
```

---

## 快速开始

```bash
# 下载并安装 rootfs
alpine download

# 启动 Alpine Linux
alpine start

# 进入 shell
alpine shell

# 查看状态
alpine status
```

---

## 完整命令参考

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
| `alpine download` | 自动下载安装（自动检测架构） |
| `alpine download aarch64` | 指定架构下载 |
| `alpine download aarch64 3.19.0` | 指定架构和版本 |
| `alpine download aarch64 3.19.0 tuna` | 指定镜像源 |
| `alpine install <文件>` | 从本地 tar.gz 文件安装 |
| `alpine mirror tuna` | 设置镜像源 |

**镜像源选项：**

| 名称 | 地址 |
|------|------|
| `tuna` | 清华大学（默认，国内推荐） |
| `ustc` | 中科大 |
| `official` | 官方源 |

### 服务管理

| 命令 | 说明 |
|------|------|
| `alpine service add <名称>` | 添加预设服务 |
| `alpine service add <名称> "命令"` | 添加自定义服务 |
| `alpine service list` | 查看服务列表 |
| `alpine service start <名称>` | 启动服务 |
| `alpine service stop <名称>` | 停止服务 |
| `alpine service restart <名称>` | 重启服务 |
| `alpine service status <名称>` | 查看状态 |
| `alpine service enable <名称>` | 启用开机自启 |
| `alpine service disable <名称>` | 禁用开机自启 |
| `alpine service logs <名称>` | 查看日志 |
| `alpine service rm <名称>` | 删除服务 |

**预设应用：**

添加预设应用时会自动配置启动命令，无需手动指定：

| 预设名 | 说明 | 自动启动命令 | 需先安装 |
|--------|------|--------------|----------|
| `openclaw` | OpenClaw 网关 | `openclaw gateway --port 18789` | `apk add openclaw` |
| `sshd` | SSH 服务 | `/usr/sbin/sshd` | `alpine ssh` 自动安装 |
| `nginx` | Web 服务器 | `nginx` | `apk add nginx` |
| `redis` | 内存数据库 | `redis-server` | `apk add redis` |
| `mysql` | 关系型数据库 | `mysqld` | `apk add mysql` |
| `postgres` | 关系型数据库 | `postgres` | `apk add postgresql` |

> ⚠️ **注意**：预设应用只是配置了启动命令，需要先安装对应的软件包才能运行。

**使用示例：**

```bash
# 以 nginx 为例
alpine shell
# 在 shell 内安装 nginx
apk add nginx
exit

# 添加预设服务（自动配置启动命令）
alpine service add nginx

# 启动服务
alpine service start nginx

# 查看状态
alpine service status nginx
```

**自定义服务：**

如果预设不满足需求，可以指定自定义启动命令：

```bash
# 自定义启动命令
alpine service add myapp "/usr/local/bin/myapp --port 8080"
alpine service start myapp
```

### SSH 配置

| 命令 | 说明 |
|------|------|
| `alpine ssh` | 一键配置 SSH（端口22，密码123456） |
| `alpine ssh 22 mypassword` | 指定端口和密码 |
| `alpine ssh start` | 启动 SSH |
| `alpine ssh stop` | 停止 SSH |
| `alpine ssh restart` | 重启 SSH |
| `alpine ssh status` | 查看状态 |

> ⚠️ **安全提示**：默认密码 `123456` 仅供测试，生产环境请务必修改！

### 软件安装

| 命令 | 说明 |
|------|------|
| `alpine install-pkg` | 安装基础工具 |
| `alpine install-pkg dev` | 安装开发环境 |
| `alpine install-pkg net` | 安装网络工具 |
| `alpine install-pkg tools` | 安装常用工具 |
| `alpine install-pkg all` | 安装全部软件 |
| `alpine install-pkg <包名>` | 安装指定软件包 |

#### 基础工具 (basic)

| 软件包 | 说明 |
|--------|------|
| `bash` | Bourne Again Shell，更强大的命令行 shell |
| `coreutils` | GNU 核心工具集（ls, cp, mv, cat 等） |
| `vim` | 经典文本编辑器 |
| `curl` | 命令行数据传输工具 |
| `wget` | 文件下载工具 |

#### 开发环境 (dev)

| 软件包 | 说明 |
|--------|------|
| `bash` | Bourne Again Shell |
| `vim` | 文本编辑器 |
| `curl` | 数据传输工具 |
| `git` | 分布式版本控制系统 |
| `python3` | Python 3 解释器 |
| `nodejs` | Node.js JavaScript 运行环境 |
| `gcc` | GNU C 编译器 |

#### 网络工具 (net)

| 软件包 | 说明 |
|--------|------|
| `bash` | Bourne Again Shell |
| `vim` | 文本编辑器 |
| `curl` | 数据传输工具 |
| `openssh` | OpenSSH 客户端和服务端 |
| `openssl` | SSL/TLS 加密工具库 |

#### 常用工具 (tools)

| 软件包 | 说明 |
|--------|------|
| `bash` | Bourne Again Shell |
| `vim` | 文本编辑器 |
| `curl` | 数据传输工具 |
| `htop` | 交互式进程查看器 |
| `tree` | 目录树显示工具 |
| `rsync` | 文件同步工具 |

#### 全部软件 (all)

包含以上所有软件包，共 12 个：`bash`, `coreutils`, `vim`, `curl`, `wget`, `git`, `python3`, `nodejs`, `gcc`, `openssh`, `htop`, `tree`, `rsync`

#### 包管理器镜像配置

安装 `python3` 或 `nodejs` 时，会自动配置国内镜像源：

| 语言 | 包管理器 | 镜像源 |
|------|----------|--------|
| Python | pip | 清华大学 pypi.tuna.tsinghua.edu.cn |
| Node.js | npm | npmmirror.com |

> 💡 **提示**：Python 的 pip 在 Alpine Linux 中需要单独安装，`install-pkg` 会自动处理。

#### 自定义安装

```bash
# 安装单个软件包
alpine install-pkg nginx

# 安装多个软件包（需要进入 shell）
alpine shell
apk add nginx redis mysql
```

### 其他命令

| 命令 | 说明 |
|------|------|
| `alpine log` | 查看最近日志 |
| `alpine module-version` | 查看模块版本 |
| `alpine module-upgrade <zip>` | 升级模块 |
| `alpine help` | 显示帮助 |

---

## 使用示例

### 示例 1：运行 Web 服务器

```bash
# 安装 nginx
alpine start
alpine shell
# 在 shell 内执行：
apk add nginx
echo "Hello from Alpine!" > /var/www/localhost/htdocs/index.html
nginx

# 或添加为服务
exit
alpine service add nginx
alpine service start nginx
```

### 示例 2：添加自定义服务

```bash
# 添加 Python HTTP 服务
alpine service add pyserver "python3 -m http.server 8080 --directory /root/web"
alpine service start pyserver
alpine service status pyserver
```

### 示例 3：SSH 远程连接

```bash
# 配置 SSH（修改默认密码！）
alpine ssh 2222 my_secure_password

# 从电脑连接
ssh root@<手机IP> -p 2222
```

---

## 目录结构

### Android 端

| 路径 | 说明 |
|------|------|
| `/data/alpine_linux/rootfs` | Alpine rootfs 根文件系统 |
| `/data/alpine_linux/services` | 服务配置文件目录 |
| `/data/alpine_linux/alpine.log` | 运行日志 |

### Alpine 内部

| 路径 | 说明 |
|------|------|
| `/mnt/sdcard` | Android 内部存储 |
| `/mnt/external_sd` | 外置 SD 卡 |
| `/var/log/<服务名>.log` | 服务日志 |

---

## 常见问题

### Q: 提示 `rootfs 不存在`？

```bash
alpine download
alpine start
```

### Q: 提示 `无法检测最新版本`？

手动指定版本：
```bash
alpine download aarch64 3.19.0
```

### Q: 如何完全卸载？

```bash
# 卸载模块（保留 rootfs）
alpine stop
# 在 Magisk Manager 中移除模块

# 完全清理（包括 rootfs）
rm -rf /data/alpine_linux
```

### Q: 如何查看日志？

```bash
# 查看最近日志
alpine log

# 完整日志文件
cat /data/alpine_linux/alpine.log
```

### Q: 服务无法启动？

检查服务日志：
```bash
alpine service logs <服务名>
```

---

## 许可证

MIT License

---

## 项目地址

| 平台 | 地址 |
|------|------|
| GitHub | https://github.com/chuanglizhe/alpine-linux-magisk |
| Gitee | https://gitee.com/chuanglizhe1/alpine-linux-magisk |

---

## 致谢

- Alpine Linux：https://alpinelinux.org
- Magisk：https://github.com/topjohnwu/Magisk
