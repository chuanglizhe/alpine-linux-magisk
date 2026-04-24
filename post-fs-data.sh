#!/system/bin/sh
#====================================================
# Alpine Linux - Post FS Data Script (Patched)
#====================================================

MODDIR="${0%/*}"
. "$MODDIR/common.sh"

inf "初始化 Alpine Linux 模块"

# 创建必要目录（确保在日志函数之前目录已存在）
mkdir -p "$R"
chmod 755 "$R"

if [ -d "$RF/usr/bin" ]; then
    echo "$RF/usr/bin:$RF/bin" > /data/adb/alpine_path
fi

inf "初始化完成"