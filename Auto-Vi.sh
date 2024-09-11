#!/bin/bash

# 检查用户是否是 root
if [[ $EUID -ne 0 ]]; then
   echo "请以 root 用户身份运行此脚本。"
   exit 1
fi

# 删除 vim-tiny 并安装 vim
apt-get remove -y vim-tiny

# 检查系统版本（用于不同系统的兼容性）
if [ -f /etc/debian_version ]; then
    # Debian 或 Ubuntu 系统
    apt-get update
    apt-get install -y vim
elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
    # CentOS 或 RHEL 系统
    yum install -y vim
else
    echo "不支持的操作系统。"
    exit 1
fi

# 判断是否已存在 .vimrc 文件
if [ -e ~/.vimrc ]; then
    echo ".vimrc 文件已存在，正在检查和添加缺失的配置。"

    # 判断并添加缺失的配置行
    grep -q "set nocompatible" ~/.vimrc || echo "set nocompatible" >> ~/.vimrc
    grep -q "set backspace=2" ~/.vimrc || echo "set backspace=2" >> ~/.vimrc
    grep -q "set number" ~/.vimrc || echo "set number" >> ~/.vimrc
    grep -q "syntax on" ~/.vimrc || echo "syntax on" >> ~/.vimrc

else
    # 如果文件不存在，则创建并写入配置
    echo "创建 .vimrc 文件并添加初始配置。"
    cat <<EOF > ~/.vimrc
set nocompatible
set backspace=2
set number
syntax on
EOF
fi
