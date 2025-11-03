#!/bin/bash

# ==============================================================================
#  该脚本用于生成一个基于硬件和网络信息的动态主机名，
#  并将其添加到 /etc/hosts 文件中，以解决 'sudo' 命令无法解析主机名的问题。
#
#  它会执行以下操作:
#  1. 检查并安装必要的工具 (curl, jq)。
#  2. 检查脚本是否以 root 权限运行。
#  3. 收集系统信息 (CPU, 内存, 硬盘, 公网IP, 地区)。
#  4. 根据收集到的信息生成一个新的、描述性的主机名。
#  5. 检查 /etc/hosts 文件中是否已存在该主机名。
#  6. 如果不存在，则安全地将新主机名追加到 '127.0.0.1' 所在的行。
# ==============================================================================

# 步骤 1: 检查脚本是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
   echo "错误: 此脚本必须以 root 权限运行。" 1>&2
   echo "请尝试使用: sudo ./your_script_name.sh"
   exit 1
fi

# 步骤 2: 检查并安装必要的工具
echo "正在检查必要的工具 (curl, jq)..."
if command -v curl &> /dev/null && command -v jq &> /dev/null
then
    echo "curl 和 jq 已安装。"
else
    echo "正在安装 curl 和 jq..."
    apt-get update > /dev/null
    if ! apt-get install -y curl jq; then
        echo "错误: 安装 curl 或 jq 失败。请手动安装后重试。"
        exit 1
    fi
fi

echo "----------------------------------------"

# 步骤 3: 收集系统信息
echo "正在收集系统信息..."
# 获取CPU核心数
cpu_cores=$(lscpu | grep '^CPU(s):' | awk '{print $2}')

# 获取内存大小 (例如 16G)
memory_size=$(free -h | awk '/^Mem:/ {print $2}')

# 获取主硬盘大小 (例如 100G)
disk_size=$(lsblk -ndo SIZE,TYPE | awk '/disk/ {print $1; exit}')

# 获取公共 IP 地址 (使用-sS4确保静默、显示错误并使用IPv4)
public_ip=$(curl -sS4 ip.sb)
if [ -z "$public_ip" ]; then
    echo "错误: 无法获取公网 IP 地址。请检查网络连接。"
    exit 1
fi

# 获取地区信息
region=$(curl -sS "https://ipinfo.io/${public_ip}/json" | jq -r .region)
# 如果地区信息为空，则使用 "Unknown"
region=${region:-Unknown}

echo "信息收集完成:"
echo "  - CPU Cores : ${cpu_cores}"
echo "  - Memory    : ${memory_size}"
echo "  - Disk Size : ${disk_size}"
echo "  - Public IP : ${public_ip}"
echo "  - Region    : ${region}"
echo "----------------------------------------"

# 步骤 4: 生成新的主机名
# 将IP中的点替换为横杠
ip_for_hostname=$(echo "${public_ip}" | tr '.' '-')
# 组合新的主机名
new_hostname="${cpu_cores}c-${memory_size}-${disk_size}-${region}-${ip_for_hostname}"

echo "根据系统信息，生成的主机名是: ${new_hostname}"
echo "----------------------------------------"


# 更改主机名
hostnamectl set-hostname "${new_hostname}"

# 步骤 5: 将新主机名添加到 /etc/hosts 文件
hosts_file="/etc/hosts"

# 检查主机名是否已存在于 /etc/hosts 文件中，避免重复添加
if grep -qP "\s${new_hostname}(\s|$)" "$hosts_file"; then
    echo "✔️ 主机名 '${new_hostname}' 已存在于 ${hosts_file}。无需操作。"
else
    echo "正在将主机名 '${new_hostname}' 添加到 ${hosts_file}..."
    
    # 使用 sed 命令安全地将主机名追加到以 127.0.0.1 开头的行的末尾
    # -i.bak 会创建一个备份文件 /etc/hosts.bak，防止意外修改
    sed -i.bak "/^127\.0\.0\.1/ s/$/ ${new_hostname}/" "$hosts_file"
    
    if [ $? -eq 0 ]; then
        echo "✅ 成功将主机名添加到 ${hosts_file}。"
        echo "现在的 '127.0.0.1' 行内容如下:"
        grep "^127\.0\.0\.1" "$hosts_file"
    else
        echo "❌ 错误: 修改 ${hosts_file} 失败。请检查文件权限。"
        exit 1
    fi
fi

echo "----------------------------------------"
echo "脚本执行完毕。"
