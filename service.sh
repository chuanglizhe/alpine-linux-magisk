#!/system/bin/sh
#====================================================
# Alpine Linux - Boot Service (Patched)
#====================================================

MODDIR="${0%/*}"
. "$MODDIR/common.sh"

# 等待系统启动完成
wait_for_boot() {
    until [ "$(getprop sys.boot_completed)" = "1" ]; do
        sleep 1
    done
    sleep 5
}

# 主函数
main() {
    inf "========================================"
    inf " Alpine Linux Service Starting"
    inf "========================================"

    # 检查 rootfs
    if ! ck; then
        wrn "rootfs 未安装，跳过自动启动"
        inf "请使用 'alpine download' 安装"
        exit 0
    fi

    # 启动 Alpine（已包含自动启动服务）
    alpine_start

    # 检查启动结果
    if run; then
        inf "Alpine Linux 已在后台运行"
    else
        err "Alpine Linux 启动失败"
    fi
}

# 后台执行
wait_for_boot && main &
