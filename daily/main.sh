#!/bin/bash

# 设置日志
LOG_DIR="~/dailylog"
LOG_FILE="$LOG_DIR/$(date +'%Y-%m-%d_%H-%M-%S').log"

mkdir -p "$LOG_DIR"  # 创建日志目录
touch "$LOG_FILE"    # 创建日志文件
# 输出日志信息到日志文件

echo "每日巡检开始！"

#全自动解决vi方向键乱跳
bash <(wget -qO- -o- https://raw.githubusercontent.com/htazq/Auto/main/Auto-Vi.sh)

#全自动修改主机名称为：cpu核心数-内存容量-硬盘容量-服务器地区-服务器IP
bash <(wget -qO- -o- https://raw.githubusercontent.com/htazq/Auto/main/change_hostname.sh)

echo "每日巡检结束！" >> "$LOG_FILE"
