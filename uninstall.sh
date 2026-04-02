#!/system/bin/sh
#====================================================
# Alpine Linux Chroot - Uninstall Script
#====================================================

MODDIR="${0%/*}"

# 加载公共函数
. "$MODDIR/common.sh"

log_info "正在卸载 Alpine Linux 模块..."

# 停止 Alpine
if alpine_is_running; then
    log_info "正在停止 Alpine Linux..."
    alpine_stop
fi

# 清理文件
rm -f /data/adb/alpine_path 2>/dev/null

# 清理日志
rm -f "$ALPINE_LOG" 2>/dev/null

# 清理 PID 文件
rm -f "$PID_FILE" 2>/dev/null

log_info "Alpine Linux 模块已卸载"
log_info "注意: Alpine rootfs 已保留在 $ALPINE_ROOTFS"
log_info "如需完全删除，请手动执行: rm -rf $ALPINE_ROOT"
