#!/bin/bash

# 检查是否已经安装了 nvm
if [ -d "$HOME/.nvm" ]; then
    echo "nvm 已经安装，无需重新安装。"
    exit 0
fi

# 下载并安装 nvm
echo "正在下载并安装最新版本的 nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')/install.sh | bash

# 激活 nvm
echo "激活 nvm..."
source "$HOME/.nvm/nvm.sh"

# 验证安装结果
if command -v nvm &>/dev/null; then
    echo "nvm 安装成功！"
    nvm --version
    exit 0
else
    echo "nvm 安装失败。"
    exit 1
fi
