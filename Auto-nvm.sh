#!/bin/bash

# 检查是否已经安装了 nvm
if [ -d "$HOME/.nvm" ]; then
    echo "nvm 已经安装，无需重新安装。"
else
    # 下载并安装 nvm
    echo "正在下载并安装最新版本的 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')/install.sh | bash
fi

# 激活 nvm
echo "激活 nvm..."
source "$HOME/.nvm/nvm.sh"

# 验证安装结果
if command -v nvm &>/dev/null; then
    echo "nvm 安装成功！"
    nvm --version

    # 自动判断当前 Shell 并加载配置文件
    SHELL_NAME=$(basename "$SHELL")

    if [ "$SHELL_NAME" = "bash" ]; then
        CONFIG_FILE="$HOME/.bashrc"
    elif [ "$SHELL_NAME" = "zsh" ]; then
        CONFIG_FILE="$HOME/.zshrc"
    else
        echo "无法确定当前 Shell，请手动加载配置文件。"
        exit 1
    fi

    # 加载配置文件
    echo "加载配置文件: $CONFIG_FILE"
    source "$CONFIG_FILE"

    echo "配置文件加载完成！"
else
    echo "nvm 安装失败。"
fi
