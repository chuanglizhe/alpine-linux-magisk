#!/system/bin/sh
#====================================================
# Alpine Linux Chroot - Uninstall Script (Patched)
#====================================================

MODDIR="${0%/*}"

# 加载公共函数
. "$MODDIR/common.sh"

inf "正在卸载 Alpine Linux 模块..."

# 停止 Alpine（修复：使用正确的函数名 run）
if run; then
    inf "正在停止 Alpine Linux..."
    alpine_stop
fi

# 清理文件
rm -f /data/adb/alpine_path 2>/dev/null

# 清理日志
rm -f "$LOG" 2>/dev/null

# 清理服务目录
rm -rf "$SVC" 2>/dev/null

inf "Alpine Linux 模块已卸载"
inf "注意: Alpine rootfs 已保留在 $RF"
inf "如需完全删除，请手动执行: rm -rf $R"
