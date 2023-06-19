#!/bin/bash

# 检测必备工具是否已安装
check_dependencies() {
  dependencies=("curl" "bash" "wget" "sudo" "git")

  for dependency in "${dependencies[@]}"; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
      echo "正在安装 $dependency ..."
      sudo apt-get install -y "$dependency"
      echo "$dependency 安装完成。"
    fi
  done
}

# 调用检测必备工具的函数
check_dependencies

# 执行 Auto-Vi.sh
bash <(curl -sSL https://raw.githubusercontent.com/htazq/Auto-Install-Docker/main/Auto-Vi.sh)

# 执行 Auto-Install-Docker.sh
bash <(curl -sSL https://raw.githubusercontent.com/htazq/Auto-Install-Docker/main/Auto-Install-Docker.sh)

# 更新系统软件
sudo apt-get update
sudo apt-get upgrade -y
