#!/system/bin/sh
# Alpine Linux - Common Functions Library v1.3.2 (Patched)

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
        v=$(curl -sL "${u}/${a}/" 2>/dev/null | grep -o 'alpine-minirootfs-[0-9.]\+-'"${a}"'.tar.gz' | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
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
    [ -f "$p" ] && inf "文件已存在" || { inf "下载: ${u}/${a}/${f}"; wget -O "$p" "${u}/${a}/${f}" 2>&1 || curl -L -o "$p" "${u}/${a}/${f}" 2>&1 || return 1; }
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
