#!/bin/bash

# ==============================================================================
# 脚本名称: Smart & Robust Docker Installer for Debian/Ubuntu (v2)
# 功能:     一个更智能、健壮的 Docker 安装脚本。
#           它不仅会彻底清理、安全安装，还会在安装后检查服务状态，并尝试自动启动失败的服务。
# ==============================================================================

# --- 步骤 0: 权限检查 ---
if [ "$EUID" -ne 0 ]; then
  echo "❌ 错误: 请以 root 权限运行此脚本 (例如: sudo ./install_docker.sh)"
  exit 1
fi

echo "--- 准备开始 Docker 的智能安装流程 ---"

# --- 步骤 1: 彻底清理旧版本和冲突包 ---
echo "⚙️  步骤 1/5: 正在清理任何旧的 Docker 版本或冲突的软件包..."
systemctl stop docker.socket >/dev/null 2>&1
systemctl stop docker.service >/dev/null 2>&1
apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io docker-doc docker-compose podman-docker containerd runc >/dev/null 2>&1
apt-get autoremove -y >/dev/null 2>&1
rm -rf /etc/apt/sources.list.d/docker.list
rm -rf /etc/apt/keyrings/docker.gpg
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
echo "✅ 清理完成。"

# --- 步骤 2: 安装必要的依赖包 ---
echo "⚙️  步骤 2/5: 正在更新软件包列表并安装必要的依赖..."
apt-get update
apt-get install -y ca-certificates curl gnupg
if [ $? -ne 0 ]; then
    echo "❌ 错误: 依赖包安装失败。请检查你的 apt 源是否正常。"
    exit 1
fi
echo "✅ 依赖安装完成。"

# --- 步骤 3: 添加 Docker 官方 GPG 密钥 (安全方式) ---
echo "⚙️  步骤 3/5: 正在添加 Docker 官方 GPG 密钥..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.gpg
if [ $? -ne 0 ]; then
    echo "❌ 错误: GPG 密钥下载失败。请检查网络连接。"
    exit 1
fi
chmod a+r /etc/apt/keyrings/docker.gpg
echo "✅ GPG 密钥添加成功。"

# --- 步骤 4: 设置 Docker 的 APT 软件源 ---
echo "⚙️  步骤 4/5: 正在设置 Docker APT 软件源..."
CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$CODENAME" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "✅ 软件源设置成功。"

# --- 步骤 5: 安装 Docker 引擎 ---
echo "⚙️  步骤 5/5: 正在安装最新版的 Docker 引擎..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
if [ $? -ne 0 ]; then
    echo "❌ 错误: Docker 引擎安装失败。请检查之前的步骤是否有错误输出。"
    exit 1
fi
systemctl enable docker >/dev/null 2>&1
echo "✅ Docker 引擎安装成功并已设置为开机自启。"

# --- 智能验证与自动修复 ---
echo ""
echo "🚀 正在智能验证安装结果并尝试自动修复..."

# 检查 Docker 服务是否在运行
if ! systemctl is-active --quiet docker; then
    echo "⚠️ 检测到 Docker 服务未在运行，正在尝试启动..."
    systemctl start docker
    sleep 2 # 等待2秒让服务有时间启动

    # 再次检查
    if ! systemctl is-active --quiet docker; then
        echo "❌ 错误: 尝试启动 Docker 服务失败！"
        echo "   请手动检查服务日志以排查问题:"
        echo "   journalctl -u docker.service -n 50 --no-pager"
        exit 1
    fi
    echo "✅ Docker 服务已成功启动！"
fi

# 运行测试容器
if docker run hello-world; then
    echo ""
    echo "🎉 恭喜！Docker 已成功安装并运行！"
else
    echo ""
    echo "❌ 错误: hello-world 测试容器运行失败，尽管服务已在运行。"
    echo "   这可能是一个更深层次的问题，请检查 Docker 日志。"
    echo "   journalctl -u docker.service -n 50 --no-pager"
fi

exit 0
