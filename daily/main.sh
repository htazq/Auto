#!/bin/bash

# 设置日志
LOG_DIR="/root/dailylog"
LOG_FILE="$LOG_DIR/$(date +'%Y-%m-%d_%H-%M-%S').log"

mkdir -p "$LOG_DIR"  # 创建日志目录
touch "$LOG_FILE"    # 创建日志文件
# 输出日志信息到日志文件
exec &>> "$LOG_FILE"

echo "每日巡检开始！"

#待补充

echo "每日巡检结束！"
