#!/bin/bash

# 卸载 vim-common 包
sudo apt-get remove -y vim-common

# 安装 vim 包
sudo apt-get install -y vim

# 编辑 .vimrc 文件
cat <<EOF > ~/.vimrc
set nocompatible
set backspace=2
set number
EOF
