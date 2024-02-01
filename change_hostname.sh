#!/bin/bash

# 检查是否已安装 curl 和 jq
if command -v curl &> /dev/null && command -v jq &> /dev/null
then
    echo "curl and jq are already installed. Skipping installation."
else
    # 安装 curl 和 jq
    apt-get update
    apt-get install -y curl jq
fi

# 获取CPU核心数
cpu_cores=$(lscpu | grep 'CPU(s):' | awk '{print $2}' | head -n 1)

# 获取内存大小
memory_size=$(lsmem | awk '/^Total online memory:/ {print $4}')

# 获取硬盘大小
disk_size=$(lsblk | awk '/disk/ {print $4}')

# 获取公共 IPV4 地址
public_ip=$(curl -sS4 ip.sb)

# 判断所处地区
region=$(curl -s "https://ipinfo.io/${public_ip}/json" | jq -r .region)

# 组合新的主机名
new_hostname="${cpu_cores}-${memory_size}-${disk_size}-${region}-${public_ip}"

# 更改主机名
echo "Setting new hostname: ${new_hostname}"
hostnamectl set-hostname "${new_hostname}"

# 显示新主机名
echo "New hostname: $(hostname)"
