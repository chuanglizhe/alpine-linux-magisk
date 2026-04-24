#!/system/bin/sh
# Alpine Linux - Common Functions Library v1.3.4

#=======================================
# 路径配置
#=======================================
R="/data/alpine_linux"
RF="$R/rootfs"
SVC="$R/services"
LOG="$R/alpine.log"

#=======================================
# 公共环境变量
#=======================================
CHROOT_ENV="HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=xterm-256color LANG=C.UTF-8"

#=======================================
# 颜色和日志
#=======================================
Rd='\033[0;31m'; Gr='\033[0;32m'; Yw='\033[1;33m'; Nc='\033[0m'
log() {
    mkdir -p "${LOG%/*}" 2>/dev/null
    if [ -f "$LOG" ]; then
        local lines=$(wc -l < "$LOG" 2>/dev/null)
        [ -n "$lines" ] && [ "$lines" -gt 1000 ] && mv "$LOG" "$LOG.1" 2>/dev/null
    fi
    local msg="$(date '+%Y-%m-%d %H:%M:%S') [$1] $2"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${Gr}[$1]${Nc} $2"
    echo "$msg" >> "$LOG"
}
err() { log ERROR "$1"; }
wrn() { log WARN "$1"; }
inf() { log INFO "$1"; }

#=======================================
# rootfs 检查
#=======================================
ck() {
    [ -d "$RF" ] || return 1
    for d in bin dev etc lib root usr sbin var tmp; do
        [ -d "$RF/$d" ] || return 1
    done
    [ -x "$RF/bin/sh" ] || [ -L "$RF/bin/sh" ]
}

#=======================================
# 运行状态
#=======================================
run() {
    mountpoint -q "$RF/proc" 2>/dev/null
}

#=======================================
# 挂载管理
#=======================================
mnt() {
    inf "挂载..."
    mount -t proc proc "$RF/proc" 2>/dev/null
    mount -t sysfs sysfs "$RF/sys" 2>/dev/null
    mount --bind /dev "$RF/dev" 2>/dev/null
    mkdir -p "$RF/dev/pts" && mount -t devpts devpts "$RF/dev/pts" 2>/dev/null
    mkdir -p "$RF/tmp" "$RF/run"
    mount -t tmpfs tmpfs "$RF/tmp" 2>/dev/null && chmod 1777 "$RF/tmp"
    mount -t tmpfs tmpfs "$RF/run" 2>/dev/null
}

umnt() {
    inf "卸载..."
    for m in run tmp dev/pts dev sys proc; do
        mountpoint -q "$RF/$m" 2>/dev/null && umount -l "$RF/$m" 2>/dev/null
    done
}

#=======================================
# 网络配置
#=======================================
net() {
    inf "配置网络..."
    cp /system/etc/resolv.conf "$RF/etc/resolv.conf" 2>/dev/null || \
        cp /etc/resolv.conf "$RF/etc/resolv.conf" 2>/dev/null || \
        echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > "$RF/etc/resolv.conf"
    grep -q "127.0.0.1" "$RF/etc/hosts" 2>/dev/null || \
        echo -e "127.0.0.1 localhost\n::1 localhost" > "$RF/etc/hosts"
}

#=======================================
# 存储挂载（修复：移除Android系统目录挂载）
#=======================================
smnt() {
    inf "挂载存储..."
    mkdir -p "$RF/mnt/sdcard" "$RF/mnt/external_sd"
    [ -d /sdcard ] && mount --bind /sdcard "$RF/mnt/sdcard" 2>/dev/null
    local sd=""; [ -d /storage/external_SD ] && sd="/storage/external_SD"; [ -d /external_sd ] && sd="/external_sd"
    [ -n "$sd" ] && mount --bind "$sd" "$RF/mnt/external_sd" 2>/dev/null
    return 0
}

sumnt() {
    for m in sdcard external_sd; do
        mountpoint -q "$RF/mnt/$m" 2>/dev/null && umount -l "$RF/mnt/$m" 2>/dev/null
    done
}

#=======================================
# 容器启动/停止（修复：完善错误处理）
#=======================================
alpine_start() {
    ck || { err "rootfs 不存在"; inf "请先运行: alpine download"; return 1; }
    run && { wrn "已在运行"; return 0; }
    inf "启动 Alpine Linux..."
    mkdir -p "$R" && chmod 755 "$R" "$RF"
    mnt || { err "挂载失败"; return 1; }
    net || { umnt; err "网络配置失败"; return 1; }
    smnt
    inf "启动完成"
    alpine_service_start_all
}

alpine_stop() {
    run || { wrn "未运行"; return 0; }
    inf "停止 Alpine Linux..."
    inf "终止进程..."
    # 终止所有以 rootfs 为根目录的进程
    local rf_path=$(echo "$RF" | sed 's#/$##')
    for pid in $(ls /proc 2>/dev/null | grep -E '^[0-9]+$'); do
        [ -L "/proc/$pid/root" ] || continue
        local root=$(readlink "/proc/$pid/root" 2>/dev/null | sed 's#/$##')
        [ "$root" = "$rf_path" ] && kill -9 "$pid" 2>/dev/null
    done
    # 再用 fuser 确保清理干净
    fuser -k "$RF" 2>/dev/null
    fuser -k "$RF"/mnt/* 2>/dev/null
    sleep 1
    sumnt; umnt
    inf "已停止"
}

#=======================================
# 执行命令（修复：使用公共环境变量）
#=======================================
alpine_exec() {
    ck || { err "rootfs 不存在"; return 1; }
    if [ -z "$1" ]; then
        chroot "$RF" /bin/sh -c "export $CHROOT_ENV; exec /bin/sh"
    else
        chroot "$RF" /bin/sh -c "export $CHROOT_ENV; $*"
    fi
}

#=======================================
# 状态查看
#=======================================
alpine_status() {
    echo "========================================"
    echo " Alpine Linux 状态"
    echo "========================================"
    run && echo -e "状态: ${Gr}运行中${Nc}" || echo -e "状态: ${Rd}已停止${Nc}"
    echo "路径: $RF"
    ck && echo -e "ROOTFS: ${Gr}已安装${Nc}" || echo -e "ROOTFS: ${Rd}未安装${Nc}"
    echo -e "\n挂载点:"
    for m in proc sys dev tmp run; do
        mountpoint -q "$RF/$m" 2>/dev/null && echo -e "  /$m: ${Gr}已挂载${Nc}" || echo -e "  /$m: ${Rd}未挂载${Nc}"
    done
    echo "========================================"
}

#=======================================
# 架构检测（修复：未知架构报错）
#=======================================
arch() {
    local a=$(uname -m 2>/dev/null); [ -z "$a" ] && a=$(getprop ro.product.cpu.abi 2>/dev/null)
    case "$a" in
        aarch64|arm64-v8a) echo "aarch64" ;;
        armv7*|armeabi-v7a) echo "armv7" ;;
        arm*|armeabi) echo "armhf" ;;
        x86_64|amd64) echo "x86_64" ;;
        x86|i686) echo "x86" ;;
        *) err "未知架构: $a"; return 1 ;;
    esac
}

#=======================================
# 镜像源
#=======================================
murl() {
    case "$1" in
        tuna) echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable" ;;
        ustc) echo "https://mirrors.ustc.edu.cn/alpine/latest-stable" ;;
        *) echo "https://dl-cdn.alpinelinux.org/alpine/latest-stable" ;;
    esac
}

#=======================================
# rootfs 下载/安装（修复：移除硬编码版本，必须检测）
#=======================================
alpine_download() {
    local a="$1" v="$2" m="${3:-tuna}"
    [ -z "$a" ] || [ "$a" = "auto" ] && { a=$(arch) || return 1; inf "架构: $a"; }
    case "$a" in aarch64|armv7|armhf|x86_64|x86) ;; *) err "不支持: $a"; return 1 ;; esac
    local u="$(murl $m)/releases"; inf "镜像: $m"
    if [ -z "$v" ]; then
        inf "检测版本..."
        # 尝试多个镜像源检测版本（按优先级）
        for mirror_url in "${u}/${a}/" \
            "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${a}/" \
            "https://mirrors.ustc.edu.cn/alpine/latest-stable/releases/${a}/"; do
            v=$(curl -sL "$mirror_url" 2>/dev/null | grep -o 'alpine-minirootfs-[0-9.]\+-'"${a}"'.tar.gz' | tail -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
            [ -n "$v" ] && break
        done
        if [ -z "$v" ]; then
            err "无法检测最新版本，请手动指定版本号"
            inf "用法: alpine download $a <版本号> $m"
            return 1
        fi
        inf "版本: $v"
    fi
    local f="alpine-minirootfs-${v}-${a}.tar.gz" d="/sdcard/Download"
    mkdir -p "$d" 2>/dev/null || { d="/data/local/tmp"; mkdir -p "$d" 2>/dev/null; }
    local p="${d}/${f}"
    # 检查已有文件完整性（防止之前下载失败保存了HTML错误页面）
    if [ -f "$p" ]; then
        local sz
        sz=$(wc -c < "$p" 2>/dev/null)
        if [ -z "$sz" ] || [ "$sz" -lt 1048576 ]; then
            wrn "文件可能损坏(${sz:-0}字节)，重新下载..."
            rm -f "$p"
        else
            inf "文件已存在"
        fi
    fi
    # 下载（仅在文件不存在时）
    if [ ! -f "$p" ]; then
        inf "下载: ${u}/${a}/${f}"
        if ! wget -O "$p" "${u}/${a}/${f}" 2>&1; then
            rm -f "$p" 2>/dev/null
            # 下载失败，尝试官方源回退
            local fallback="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${a}/${f}"
            inf "镜像下载失败，尝试官方源: ${fallback}"
            curl -L -o "$p" "$fallback" 2>&1 || { rm -f "$p"; return 1; }
        fi
        # 验证下载文件完整性
        sz=$(wc -c < "$p" 2>/dev/null)
        if [ -z "$sz" ] || [ "$sz" -lt 1048576 ]; then
            err "下载文件可能损坏(${sz:-0}字节)"
            rm -f "$p"
            return 1
        fi
    fi
    alpine_install "$p" && alpine_set_mirror "$m"
}

alpine_install() {
    local f="$1"
    [ -z "$f" ] && { err "用法: alpine install <文件>"; return 1; }
    [ ! -f "$f" ] && { err "文件不存在: $f"; return 1; }
    inf "安装到: $RF"
    [ -d "$RF" ] && [ "$(ls -A $RF 2>/dev/null)" ] && { wrn "备份旧 rootfs..."; mv "$RF" "$RF.bak"; }
    mkdir -p "$RF"; inf "解压..."
    case "$f" in
        *.tar.gz|*.tgz) tar -xzf "$f" -C "$RF" ;;
        *.tar.xz) tar -xJf "$f" -C "$RF" ;;
        *.tar.bz2) tar -xjf "$f" -C "$RF" ;;
        *) err "不支持格式"; rm -rf "$RF"; return 1 ;;
    esac || { err "解压失败"; rm -rf "$RF"; return 1; }
    [ ! -d "$RF/bin" ] && { err "结构错误"; rm -rf "$RF"; return 1; }
    mkdir -p "$RF/etc/apk" "$RF/root" "$RF/tmp" "$RF/var/run"
    chmod 1777 "$RF/tmp"
    chmod 700 "$RF/root"
    alpine_set_mirror tuna
    inf "安装完成，运行: alpine start"
}

#=======================================
# 镜像设置
#=======================================
alpine_set_mirror() {
    [ ! -d "$RF" ] && { err "rootfs 未安装"; return 1; }
    local u=$(murl "$1"); mkdir -p "$RF/etc/apk"
    echo -e "${u}/main\n${u}/community" > "$RF/etc/apk/repositories"
    inf "镜像: $1"
}

#=======================================
# 包管理器镜像配置
#=======================================
setup_npm_mirror() {
    if ! alpine_exec "command -v npm >/dev/null 2>&1"; then
        inf "安装 npm..."
        alpine_exec "apk add npm" 2>/dev/null || return
    fi
    inf "配置 npm 国内镜像..."
    alpine_exec "npm config set registry https://registry.npmmirror.com" 2>/dev/null
    inf "npm 镜像: npmmirror.com"
}

setup_pip_mirror() {
    alpine_exec "command -v pip3 >/dev/null 2>&1" && {
        inf "配置 pip 国内镜像..."
        alpine_exec "mkdir -p /root && cat > /root/pip.conf << 'EOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple" 2>/dev/null
        inf "pip 镜像: pypi.tuna.tsinghua.edu.cn"
        return
    }
    # pip 不存在，安装 py3-pip 后配置镜像
    inf "安装 pip..."
    alpine_exec "apk add py3-pip" 2>/dev/null || return
    inf "配置 pip 国内镜像..."
    alpine_exec "mkdir -p /root && cat > /root/pip.conf << 'EOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple" 2>/dev/null
    inf "pip 镜像: pypi.tuna.tsinghua.edu.cn"
}

#=======================================
# OpenClaw 环境配置
#=======================================
setup_openclaw() {
    alpine_exec "command -v openclaw >/dev/null 2>&1" || return
    inf "配置 OpenClaw 环境..."
    # 安装 bash（OpenClaw exec 依赖）
    alpine_exec "command -v bash >/dev/null 2>&1 || apk add bash" 2>/dev/null
    # 设置 SHELL 环境变量
    alpine_exec "grep -q 'SHELL=' /etc/profile 2>/dev/null || echo 'export SHELL=/bin/bash' >> /etc/profile" 2>/dev/null
    alpine_exec "grep -q 'SHELL=' /root/.bashrc 2>/dev/null || echo 'export SHELL=/bin/bash' >> /root/.bashrc" 2>/dev/null
    # 配置 exec 权限（合并到已有配置，不覆盖）
    alpine_exec "mkdir -p /root/.openclaw"
    local cfg="$RF/root/.openclaw/openclaw.json"
    if [ -f "$cfg" ]; then
        # 已有配置，添加 exec 权限
        if grep -q '"exec"' "$cfg" 2>/dev/null; then
            # 已有 exec 配置，修改 security 为 allow
            sed -i 's/"security"[[:space:]]*:[[:space:]]*"[^"]*"/"security": "full"/' "$cfg" 2>/dev/null
        else
            # 没有 exec 配置，在 tools 块中添加
            sed -i 's/"tools"[[:space:]]*:[[:space:]]*{/"tools": {"exec": {"security": "full"},/' "$cfg" 2>/dev/null
        fi
    else
        # 没有配置文件，创建默认配置
        cat > "$cfg" << 'CONF'
{
  "tools": {
    "exec": {
      "security": "full"
    }
  }
}
CONF
    fi
    inf "OpenClaw 环境配置完成"
}

#=======================================
# 软件安装
#=======================================
alpine_install_packages() {
    run || { wrn "启动中..."; alpine_start || return 1; }
    local p; case "$1" in
        ""|basic) p="bash coreutils vim curl wget" ;;
        dev) p="bash vim curl git python3 nodejs gcc" ;;
        net) p="bash vim curl openssh openssl" ;;
        tools) p="bash vim curl htop tree rsync" ;;
        all) p="bash vim curl git python3 nodejs gcc openssh htop tree rsync" ;;
        *) p="$1" ;;
    esac
    inf "安装: $p"; alpine_exec "apk update && apk add $p" || { err "失败"; return 1; }
    # 检测 nodejs/python3，配置包管理器国内镜像
    case " $p " in
        *" nodejs "*) setup_npm_mirror ;;
    esac
    case " $p " in
        *" python3 "*) setup_pip_mirror ;;
    esac
    inf "完成"
}

#=======================================
# 预设应用
#=======================================
preset() {
    case "$1" in
        openclaw) echo "openclaw gateway --port 18789" ;;
        hermes) echo "/root/.hermes/hermes-agent/venv/bin/hermes gateway" ;;
        sshd) echo "/usr/sbin/sshd" ;;
        nginx) echo "nginx" ;;
        redis) echo "redis-server" ;;
        mysql) echo "mysqld" ;;
        postgres) echo "postgres" ;;
        *) echo "$1" ;;
    esac
}

#=======================================
# 服务管理（修复：命令注入风险、子shell问题、服务停止）
#=======================================
alpine_service() {
    local cmd="$1" name="$2" arg="$3"
    mkdir -p "$SVC"
    # 修复：服务名称校验，防止命令注入
    case "$name" in
        *[!a-zA-Z0-9_-]*) err "服务名只能包含字母、数字、下划线和连字符"; return 1 ;;
    esac
    case "$cmd" in
        add)
            [ -z "$name" ] && { err "用法: alpine service add <名称> [命令]"; return 1; }
            local c="${arg:-$(preset $name)}"
            [ "$c" = "openclaw gateway" ] && c="openclaw gateway --port 18789"
            cat > "$SVC/$name.service" << EOF
[Unit]
Description=$name

[Service]
ExecStart=$c
EOF
            touch "$SVC/$name.enabled"
            inf "已添加: $name ($c)"
            ;;
        list)
            echo "服务列表:"
            ls "$SVC"/*.service 2>/dev/null | while read f; do
                [ -f "$f" ] || continue
                local n=$(basename "$f" .service)
                [ -f "$SVC/$n.enabled" ] && echo "  $n *" || echo "  $n"
            done
            ;;
        start)
            [ -f "$SVC/$name.service" ] || { err "服务不存在: $name"; return 1; }
            run || alpine_start
            # OpenClaw 启动前自动配置环境
            [ "$name" = "openclaw" ] && setup_openclaw
            local c=$(grep "^ExecStart=" "$SVC/$name.service" | cut -d= -f2-)
            inf "启动: $name"
            # 记录服务 PID
            alpine_exec "nohup $c > /var/log/$name.log 2>&1 & echo \$! > /var/run/$name.pid"
            ;;
        stop)
            inf "停止: $name"
            # 修复：使用 PID 文件精确停止
            alpine_exec "if [ -f /var/run/$name.pid ]; then kill \$(cat /var/run/$name.pid) 2>/dev/null; rm -f /var/run/$name.pid; else pkill -f '$name'; fi" 2>/dev/null
            ;;
        restart) alpine_service stop "$name"; sleep 1; alpine_service start "$name" ;;
        status) alpine_exec "pgrep -f '$name'" >/dev/null 2>&1 && echo -e "$name: ${Gr}运行中${Nc}" || echo -e "$name: ${Rd}未运行${Nc}" ;;
        enable) [ -f "$SVC/$name.service" ] && { touch "$SVC/$name.enabled"; inf "已启用: $name"; } ;;
        disable) rm -f "$SVC/$name.enabled"; inf "已禁用: $name" ;;
        logs) alpine_exec "tail -50 /var/log/$name.log" ;;
        rm) rm -f "$SVC/$name.service" "$SVC/$name.enabled"; inf "已删除: $name" ;;
        *) echo "用法: alpine service <add|list|start|stop|restart|status|enable|disable|logs|rm>"; echo "预设: openclaw, sshd, nginx, redis, mysql, postgres" ;;
    esac
}

#=======================================
# 启动已启用服务（修复：避免管道子shell）
#=======================================
alpine_service_start_all() {
    [ ! -d "$SVC" ] && return
    # 修复：使用 for 循环替代管道
    for f in "$SVC"/*.enabled; do
        [ -f "$f" ] || continue
        alpine_service start "$(basename "$f" .enabled)" 2>/dev/null
    done
}

#=======================================
# Shell（修复：使用公共环境变量）
#=======================================
alpine_shell() {
    run || { wrn "启动中..."; alpine_start || return 1; }
    local s="/bin/sh"; [ -x "$RF/bin/bash" ] && s="/bin/bash"
    inf "进入 shell"
    chroot "$RF" /bin/sh -c "export $CHROOT_ENV; cd /root; exec $s -l"
}

#=======================================
# SSH 配置/管理（保持原有逻辑不变）
#=======================================
alpine_ssh() {
    run || { err "未运行"; return 1; }
    case "$1" in
        setup|"")
            local p="${2:-22}" pw="${3:-123456}" pr="${4:-yes}"
            run || alpine_start
            inf "安装 OpenSSH..."; alpine_exec "apk update && apk add openssh openssh-server" || return 1
            alpine_exec "ssh-keygen -A" 2>/dev/null
            cat > "$RF/etc/ssh/sshd_config" << EOF
Port $p
PermitRootLogin $pr
PasswordAuthentication yes
PubkeyAuthentication yes
UseDNS no
EOF
            echo "root:$pw" | chroot "$RF" /usr/sbin/chpasswd 2>/dev/null
            alpine_exec "/usr/sbin/sshd" 2>/dev/null
            echo "========================================"; echo " SSH 配置完成"; echo "========================================"
            echo "端口: $p"; echo "用户: root"; echo "密码: $pw"; echo "========================================"
            ;;
        start) alpine_exec "/usr/sbin/sshd" && inf "已启动" ;;
        stop) alpine_exec "pkill sshd" && inf "已停止" ;;
        restart) alpine_exec "pkill sshd; sleep 1; /usr/sbin/sshd" && inf "已重启" ;;
        status) alpine_exec "pgrep sshd" >/dev/null 2>&1 && echo -e "SSH: ${Gr}运行中${Nc}" || echo -e "SSH: ${Rd}未运行${Nc}" ;;
    esac
}

# 兼容旧函数名
alpine_setup_ssh() { alpine_ssh setup "$@"; }
alpine_ssh_manage() { alpine_ssh "$@"; }

#=======================================
# GitHub 下载加速（多源回退）
#=======================================
# Gitee 配置（用户可通过环境变量覆盖）
GITEE_USER="${GITEE_USER:-}"
GITEE_TOKEN="${GITEE_TOKEN:-}"

gh_download_repo() {
    local owner="$1" repo="$2" dest="$3"

    inf "下载 ${owner}/${repo} ..."

    # 确保 git 已安装
    alpine_exec "command -v git >/dev/null 2>&1 || apk add git" 2>/dev/null

    # 1. 尝试 Gitee 镜像（同名仓库）
    local gitee_repo_url="https://gitee.com/${owner}/${repo}.git"
    inf "尝试 Gitee 镜像 ..."
    if alpine_exec "git clone --depth 1 '${gitee_repo_url}' '${dest}'" 2>/dev/null; then
        inf "Gitee 下载成功"
        return 0
    fi
    alpine_exec "rm -rf '${dest}'" 2>/dev/null

    # 2. 用户配置了 Gitee，尝试从用户仓库克隆
    if [ -n "$GITEE_USER" ]; then
        local user_gitee_url="https://gitee.com/${GITEE_USER}/${repo}.git"
        inf "尝试 Gitee 用户镜像 (${GITEE_USER}) ..."
        if alpine_exec "git clone --depth 1 '${user_gitee_url}' '${dest}'" 2>/dev/null; then
            inf "Gitee 用户镜像下载成功"
            return 0
        fi
        alpine_exec "rm -rf '${dest}'" 2>/dev/null
    fi

    # 3. 询问是否配置 Gitee（仅当未配置时）
    if [ -z "$GITEE_USER" ] || [ -z "$GITEE_TOKEN" ]; then
        echo ""
        echo "GitHub 下载可能较慢，配置 Gitee 可加速下载"
        printf "是否配置 Gitee？[Y/n] "
        local answer
        read -r answer 2>/dev/null || answer=""
        case "$answer" in
            n|N|no|NO) ;;
            *)
                printf "请输入 Gitee 用户名: "
                read -r GITEE_USER 2>/dev/null
                printf "请输入 Gitee 私人令牌: "
                read -r GITEE_TOKEN 2>/dev/null
                if [ -z "$GITEE_USER" ] || [ -z "$GITEE_TOKEN" ]; then
                    wrn "输入为空，跳过 Gitee 配置"
                else
                    inf "Gitee 配置: $GITEE_USER"
                fi
                ;;
        esac
    fi

    # 4. 配置了 Gitee，自动创建镜像仓库并同步
    if [ -n "$GITEE_USER" ] && [ -n "$GITEE_TOKEN" ]; then
        inf "尝试在 Gitee 创建镜像 ..."
        # 创建 Gitee 仓库（带 import_url 自动从 GitHub 导入）
        local create_result
        create_result=$(curl -s -X POST "https://gitee.com/api/v5/user/repos" \
            -d "access_token=${GITEE_TOKEN}" \
            -d "name=${repo}" \
            -d "private=true" \
            -d "auto_init=false" \
            -d "import_url=https://github.com/${owner}/${repo}.git" 2>/dev/null)
        if echo "$create_result" | grep -q '"id"'; then
            inf "正在从 GitHub 导入到 Gitee，等待同步..."
            local i=0
            while [ $i -lt 24 ]; do
                sleep 5
                inf "等待同步... ($((i*5))秒)"
                local user_gitee_url="https://gitee.com/${GITEE_USER}/${repo}.git"
                if alpine_exec "git clone --depth 1 '${user_gitee_url}' '${dest}'" 2>/dev/null; then
                    inf "Gitee 镜像下载成功"
                    return 0
                fi
                alpine_exec "rm -rf '${dest}'" 2>/dev/null
                i=$((i+1))
            done
            wrn "Gitee 导入超时，回退到 GitHub"
        else
            wrn "Gitee 创建仓库失败，回退到 GitHub"
        fi
    fi

    # 5. GitHub codeload 下载压缩包
    inf "尝试 GitHub codeload ..."
    alpine_exec "mkdir -p /tmp/gh-dl" 2>/dev/null
    local gh_url="https://codeload.github.com/${owner}/${repo}/zip/refs/heads/main"
    if alpine_exec "wget -q -O /tmp/gh-dl/repo.zip '${gh_url}' 2>/dev/null || curl -sL -o /tmp/gh-dl/repo.zip '${gh_url}'"; then
        if alpine_exec "mkdir -p '${dest}' && cd /tmp/gh-dl && unzip -q -o repo.zip -d extracted 2>/dev/null && cp -r extracted/*/* '${dest}'/ 2>/dev/null || cp -r extracted/* '${dest}'/ 2>/dev/null"; then
            alpine_exec "rm -rf /tmp/gh-dl"
            inf "GitHub 下载成功"
            return 0
        fi
    fi
    alpine_exec "rm -rf /tmp/gh-dl" 2>/dev/null

    # 6. 最后回退：git clone
    inf "尝试 git clone ..."
    alpine_exec "git clone --depth 1 https://github.com/${owner}/${repo}.git '${dest}'" || { alpine_exec "rm -rf '${dest}'" 2>/dev/null; err "下载失败，请检查网络"; return 1; }
}

#=======================================
# Hermes Agent 一键安装
#=======================================
alpine_install_hermes() {
    run || { wrn "启动中..."; alpine_start || return 1; }
    inf "========================================"
    inf " Hermes Agent 一键安装"
    inf "========================================"

    # 1. 安装系统依赖
    inf "安装系统依赖..."
    alpine_exec "apk update && apk add python3 py3-pip python3-dev gcc musl-dev libffi-dev make git nodejs npm ripgrep" || { err "系统依赖安装失败"; return 1; }

    # 2. 配置包管理器国内镜像
    setup_npm_mirror
    setup_pip_mirror

    # 3. 下载 Hermes Agent 源码
    inf "下载 Hermes Agent 源码..."
    if alpine_exec "[ -d /root/.hermes/hermes-agent ]"; then
        inf "已有安装，更新中..."
        alpine_exec "cd /root/.hermes/hermes-agent && git pull --ff-only 2>/dev/null || true"
    else
        gh_download_repo "NousResearch" "hermes-agent" "/root/.hermes/hermes-agent" || { err "下载失败，请检查网络"; return 1; }
    fi

    # 4. 创建虚拟环境
    inf "创建 Python 虚拟环境..."
    alpine_exec "cd /root/.hermes/hermes-agent && python3 -m venv venv" || { err "创建虚拟环境失败"; return 1; }

    # 5. 安装 Python 依赖
    inf "安装 Python 依赖（可能需要几分钟）..."
    alpine_exec "cd /root/.hermes/hermes-agent && ./venv/bin/pip install --upgrade pip setuptools wheel" 2>/dev/null
    alpine_exec "cd /root/.hermes/hermes-agent && ./venv/bin/pip install -e '.[all]'" || {
        wrn "完整安装失败，尝试基础安装..."
        alpine_exec "cd /root/.hermes/hermes-agent && ./venv/bin/pip install -e '.'" || { err "依赖安装失败"; return 1; }
    }

    # 6. 安装 Node.js 依赖
    inf "安装 Node.js 依赖..."
    alpine_exec "cd /root/.hermes/hermes-agent && npm install --silent" 2>/dev/null || wrn "Node.js 依赖安装失败（浏览器工具可能不可用）"

    # 7. 配置 PATH 和命令链接
    inf "配置命令..."
    alpine_exec "ln -sf /root/.hermes/hermes-agent/venv/bin/hermes /usr/local/bin/hermes" 2>/dev/null
    alpine_exec "grep -q '.hermes' /root/.bashrc || echo 'export PATH=/root/.hermes/hermes-agent/venv/bin:\$PATH' >> /root/.bashrc"

    # 8. 初始化配置目录
    inf "初始化配置..."
    alpine_exec "mkdir -p /root/.hermes/{cron,sessions,logs,pairing,hooks,image_cache,audio_cache,memories,skills}"
    alpine_exec "[ -f /root/.hermes/.env ] || touch /root/.hermes/.env"
    alpine_exec "[ -f /root/.hermes/config.yaml ] || touch /root/.hermes/config.yaml"

    inf "========================================"
    inf " Hermes Agent 安装完成！"
    inf "========================================"
    inf "使用方法:"
    inf "  hermes setup    - 配置 API 密钥"
    inf "  hermes          - 开始对话"
    inf "  hermes gateway  - 启动网关服务"
    inf ""
    inf "配置文件:"
    inf "  /root/.hermes/.env        - API 密钥"
    inf "  /root/.hermes/config.yaml - 配置文件"
    inf "========================================"
}

#=======================================
# 模块更新
#=======================================
alpine_update() {
    local z="${1:-/sdcard/Download/alpine-linux.zip}"
    [ ! -f "$z" ] && { err "文件不存在: $z"; return 1; }
    local t="/data/local/tmp/alpine-update"; rm -rf "$t"; mkdir -p "$t"
    inf "解压..."; unzip -o "$z" -d "$t" >/dev/null 2>&1 || { rm -rf "$t"; return 1; }
    [ -f "$t/common.sh" ] || { err "格式错误"; rm -rf "$t"; return 1; }
    inf "更新..."
    cp -f "$t/"*.sh "$t/module.prop" /data/adb/modules/alpine_linux/ 2>/dev/null
    cp -f "$t/system/bin/"* /data/adb/modules/alpine_linux/system/bin/ 2>/dev/null
    chmod +x /data/adb/modules/alpine_linux/*.sh /data/adb/modules/alpine_linux/system/bin/*
    rm -rf "$t"; inf "完成，请重启"
}

# 兼容旧函数名
alpine_update_auto() { alpine_update; }
alpine_update_local() { alpine_update "$1"; }
