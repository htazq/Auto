#!/bin/bash

# 安装 curl 和 jq
apt-get update
apt-get install -y curl jq

# 获取CPU核心数
cpu_cores=$(lscpu | grep 'CPU(s):' | awk '{print $2}' | head -n 1)

# 获取内存大小
memory_size=$(lsmem | awk '/^Total online memory:/ {print $4}')

# 获取硬盘大小
disk_size=$(lsblk | awk '/disk/ {print $4}')

# 获取公共 IP 地址
public_ip=$(curl -s https://api64.ipify.org?format=json | jq -r .ip)

# 判断所处地区
region=$(curl -s "https://ipinfo.io/${public_ip}/json" | jq -r .region)

# 组合新的主机名
new_hostname="${cpu_cores}-${memory_size}-${disk_size}-${region}-${public_ip}"

# 更改主机名
echo "Setting new hostname: ${new_hostname}"
hostnamectl set-hostname "${new_hostname}"

# 显示新主机名
echo "New hostname: $(hostname)"
