#!/bin/bash

# 尝试设置http代理

# 定义目标目录和文件路径
TARGET_DIR="${HOME}/.hall-command/command/source"
TARGET_FILE="${TARGET_DIR}/http_proxy_set.sh"

# 创建目标目录（如果不存在）
mkdir -p "${TARGET_DIR}"

# 首先尝试直接下载
echo "尝试直接下载 http_proxy_set.sh..."
if curl -fsSL -o "${TARGET_FILE}" "https://raw.githubusercontent.com/QuietSugar/hall-command/refs/heads/master/command/http_proxy_set.sh"; then
    echo "直接下载成功，执行脚本..."
    # shellcheck source=/dev/null
    source "${TARGET_FILE}"
    setup_proxy
else
    echo "直接下载失败，尝试通过代理下载..."
    # 尝试通过代理下载
    if curl -fsSL -o "${TARGET_FILE}" "https://gh-proxy.com/https://raw.githubusercontent.com/QuietSugar/hall-command/refs/heads/master/command/http_proxy_set.sh"; then
        echo "代理下载成功，执行脚本..."
        # shellcheck source=/dev/null
        source "${TARGET_FILE}"
        setup_proxy
    else
        echo "通过代理下载也失败，无法获取脚本"
        # 清理可能创建的空文件
        rm -f "${TARGET_FILE}"
    fi
fi
