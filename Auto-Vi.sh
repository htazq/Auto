#!/bin/bash

# 判断是否已安装 vim
if command -v vim &> /dev/null
then
    echo "Vim is already installed. Skipping installation."
else
    # 卸载 vim-common 包
    if dpkg -l | grep -q vim-common
    then
        sudo apt-get remove -y vim-common
    fi

    # 安装 vim 包
    sudo apt-get install -y vim
fi

# 判断是否已存在 .vimrc 文件
if [ -e ~/.vimrc ]
then
    echo "The .vimrc file already exists. Checking and adding missing configurations."

    # 判断并添加缺失的配置行
    if ! grep -q "set nocompatible" ~/.vimrc
    then
        echo "set nocompatible" >> ~/.vimrc
    fi

    if ! grep -q "set backspace=2" ~/.vimrc
    then
        echo "set backspace=2" >> ~/.vimrc
    fi

    if ! grep -q "set number" ~/.vimrc
    then
        echo "set number" >> ~/.vimrc
    fi

    if ! grep -q "syntax on" ~/.vimrc
    then
        echo "syntax on" >> ~/.vimrc
    fi
else
    # 如果文件不存在，则创建并写入配置
    echo "Creating .vimrc file with initial configurations."
    cat <<EOF > ~/.vimrc
set nocompatible
set backspace=2
set number
syntax on
EOF
fi
