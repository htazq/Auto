#!/bin/bash

# Check if Docker and Docker Compose are already installed
if command -v docker >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
  echo "Docker is already installed."
  exit 0
fi

# 获取操作系统信息
OS_ID=$(grep -w ID /etc/os-release | cut -d '=' -f 2 | tr -d '"')
OS_VERSION_ID=$(grep -w VERSION_ID /etc/os-release | cut -d '=' -f 2 | tr -d '"')

# 根据操作系统判断
if [[ "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" ]]; then
  # Debian 和 Ubuntu 系统
  apt update
  apt upgrade -y

  # 安装必要的包
  apt install -y curl gnupg2 software-properties-common

  # 添加 Docker GPG 密钥
  curl -fsSL https://download.docker.com/linux/$OS_ID/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  # 添加 Docker APT 源
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS_ID $(grep VERSION_CODENAME /etc/os-release | cut -d '=' -f 2) stable" > /etc/apt/sources.list.d/docker.list

  # 更新软件包列表
  apt update

  # 安装 Docker 和 Docker Compose
  apt install -y docker-ce docker-ce-cli containerd.io

  # 安装最新版本的 Docker Compose
  DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
  curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  
  # 启动 Docker 服务并设置开机自启动
  systemctl start docker
  systemctl enable docker

elif [[ "$OS_ID" == "centos" ]]; then
  # CentOS 系统
  yum install -y yum-utils device-mapper-persistent-data lvm2

  # 添加 Docker YUM 源
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

  # 安装 Docker 和 Docker Compose
  yum install -y docker-ce docker-ce-cli containerd.io 
  
  # 安装最新版本的 Docker Compose
  DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
  curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  # 启动 Docker 服务并设置开机自启动
  systemctl start docker
  systemctl enable docker

else
  echo "Unsupported operating system."
  exit 1
fi

# 验证安装
docker --version
docker-compose --version
