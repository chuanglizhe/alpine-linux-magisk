#!/system/bin/sh
#====================================================
# Alpine Linux Chroot - Post FS Data Script
#====================================================

MODDIR="${0%/*}"
. "$MODDIR/common.sh"

inf "初始化 Alpine Linux 模块"

# 创建必要目录
mkdir -p "$R"
chmod 755 "$R"

# 设置 PATH 环境变量 (systemless)
if [ -d "$RF/usr/bin" ]; then
    echo "$RF/usr/bin:$RF/bin" > /data/adb/alpine_path
fi

inf "初始化完成"
