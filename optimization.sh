#!/bin/bash
# ==============================================================================
# Debian 13 Server Initialization & Optimization Script
# 功能: 源检查 + 常用软件安装 + BBR加速 + Ulimit解锁 + Docker调优
# ==============================================================================

# 颜色定义
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# 检查 Root 权限
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: 本脚本必须以 root 权限运行！${RESET}" 
   exit 1
fi

echo -e "${GREEN}>>> [1/7] 开始 Debian 13 初始化与调优...${RESET}"

# ------------------------------------------------------------------------------
# 1. 检查软件源并更新 (Check APT Sources)
# ------------------------------------------------------------------------------
echo -e "${YELLOW}>>> 正在测试软件源连通性...${RESET}"

# 尝试更新源，如果失败则报错停止，避免安装软件时卡死
if apt-get update -y; then
    echo -e "${GREEN}>>> 软件源连接正常！${RESET}"
else
    echo -e "${RED}>>> Error: 软件源更新失败！请检查网络或 /etc/apt/sources.list${RESET}"
    echo "脚本将跳过软件安装步骤，仅执行内核调优..."
    SKIP_INSTALL=true
fi

# ------------------------------------------------------------------------------
# 2. 安装常用运维组件 (Install Essentials)
# ------------------------------------------------------------------------------
if [ "$SKIP_INSTALL" != "true" ]; then
    echo -e "${YELLOW}>>> 正在安装常用必备软件...${RESET}"
    
    # 常用工具列表
    # net-tools: 包含 ifconfig, netstat
    # dnsutils: 包含 dig, nslookup
    # htop/btop: 更好看的系统监控
    # jq: 处理 json 脚本必备
    # socat: 端口转发神器
    PACKAGES="curl wget git bash-completion vim nano unzip zip tar htop btop net-tools dnsutils lsof socat jq iputils-ping ca-certificates gnupg lsb-release"
    
    # 静默安装，忽略交互界面
    DEBIAN_FRONTEND=noninteractive apt-get install -y $PACKAGES
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}>>> 常用软件安装完成！${RESET}"
    else
        echo -e "${RED}>>> 警告: 部分软件安装失败，请稍后手动检查。${RESET}"
    fi
fi

# ------------------------------------------------------------------------------
# 3. 备份配置文件
# ------------------------------------------------------------------------------
echo -e "${YELLOW}>>> [2/7] 备份关键配置文件...${RESET}"
cp /etc/sysctl.conf /etc/sysctl.conf.bak.$(date +%F-%H%M)
cp /etc/security/limits.conf /etc/security/limits.conf.bak.$(date +%F-%H%M)
cp /etc/systemd/system.conf /etc/systemd/system.conf.bak.$(date +%F-%H%M)
[ -f /etc/docker/daemon.json ] && cp /etc/docker/daemon.json /etc/docker/daemon.json.bak.$(date +%F-%H%M)

# ------------------------------------------------------------------------------
# 4. 加载内核模块
# ------------------------------------------------------------------------------
echo -e "${YELLOW}>>> [3/7] 加载网络模块...${RESET}"
modprobe br_netfilter
modprobe overlay
cat > /etc/modules-load.d/server-tuning.conf <<EOF
br_netfilter
overlay
EOF

# ------------------------------------------------------------------------------
# 5. Ulimit 解锁 (最大文件打开数)
# ------------------------------------------------------------------------------
echo -e "${YELLOW}>>> [4/7] 解锁系统文件描述符限制 (Ulimit)...${RESET}"

# 用户级限制
cat > /etc/security/limits.d/20-nproc.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
root soft nproc 1048576
root hard nproc 1048576
EOF

# Systemd 全局限制
sed -i 's/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1048576/' /etc/systemd/system.conf
sed -i 's/^#DefaultLimitNPROC=.*/DefaultLimitNPROC=1048576/' /etc/systemd/system.conf
sed -i 's/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1048576/' /etc/systemd/user.conf

# ------------------------------------------------------------------------------
# 6. Sysctl 内核参数深度调优
# ------------------------------------------------------------------------------
echo -e "${YELLOW}>>> [5/7] 写入高性能内核参数 (BBR + Docker)...${RESET}"

cat > /etc/sysctl.d/99-server-tuning.conf <<EOF
# --- BBR & 网络核心 ---
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# --- Docker/虚拟化网络支持 ---
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-arptables = 1

# --- 内存与 Swap (优先物理内存) ---
vm.swappiness = 1
vm.dirty_ratio = 20
vm.dirty_background_ratio = 10

# --- 连接复用与超时 ---
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_fastopen = 3

# --- 高并发队列与缓冲区 ---
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_syncookies = 1
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432

# --- 文件系统监控 (Inotify) ---
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 8192
EOF

# ------------------------------------------------------------------------------
# 7. Docker Daemon 配置
# ------------------------------------------------------------------------------
echo -e "${YELLOW}>>> [6/7] 优化 Docker 配置...${RESET}"
mkdir -p /etc/docker
if [ ! -f /etc/docker/daemon.json ]; then
    cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 1048576,
      "Soft": 1048576
    }
  },
  "storage-driver": "overlay2"
}
EOF
else
    echo "检测到 daemon.json 已存在，跳过覆盖。"
fi

# ------------------------------------------------------------------------------
# 8. 应用与收尾
# ------------------------------------------------------------------------------
echo -e "${YELLOW}>>> [7/7] 应用更改...${RESET}"
sysctl --system > /dev/null 2>&1

# 自动激活 bash-completion (当前会话)
if [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

echo -e "${GREEN}"
echo "==========================================================="
echo "   🎉 恭喜！Debian 13 服务器初始化与调优已完成！"
echo "==========================================================="
echo "   1. 基础软件    : 已安装 (Curl, Wget, Git, Htop, Btop...)"
echo "   2. BBR 加速    : 已启用"
echo "   3. Ulimit      : 已设为 1,048,576"
echo "   4. Docker环境  : 网络转发开启, 日志轮转已配置"
echo "   5. Swap        : 已优化 (Swappiness=1)"
echo ""
echo "   👉 建议: 请执行 'reboot' 重启服务器以确保所有设置生效。"
echo "==========================================================="
echo -e "${RESET}"
