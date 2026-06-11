#!/bin/bash

PROXY_CONFIG_FILE="${HOME}/.proxy_config"

function setup_proxy_interactive() {
    echo "=== HTTP/HTTPS 代理设置 ==="
    echo ""
    
    read -p "请输入代理服务器地址 (如: 127.0.0.1): " PROXY_HOST
    if [ -z "$PROXY_HOST" ]; then
        echo "错误: 代理地址不能为空"
        return 1
    fi
    
    read -p "请输入代理端口 (如: 7890): " PROXY_PORT
    if [ -z "$PROXY_PORT" ]; then
        echo "错误: 代理端口不能为空"
        return 1
    fi
    
    read -p "请输入代理用户名 (可选，按回车跳过): " PROXY_USER
    read -p "请输入代理密码 (可选，按回车跳过): " PROXY_PASS
    
    local PROXY_URL=""
    if [ -n "$PROXY_USER" ] && [ -n "$PROXY_PASS" ]; then
        PROXY_URL="http://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}"
    else
        PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
    fi
    
    mkdir -p "$(dirname "${PROXY_CONFIG_FILE}")"
    
    cat > "${PROXY_CONFIG_FILE}" << EOF
export http_proxy="${PROXY_URL}"
export https_proxy="${PROXY_URL}"
export HTTP_PROXY="${PROXY_URL}"
export HTTPS_PROXY="${PROXY_URL}"
EOF
    
    export http_proxy="${PROXY_URL}"
    export https_proxy="${PROXY_URL}"
    export HTTP_PROXY="${PROXY_URL}"
    export HTTPS_PROXY="${PROXY_URL}"
    
    echo ""
    echo "✅ 代理配置已保存到 ${PROXY_CONFIG_FILE}"
    echo "✅ 当前终端会话已应用代理设置"
    echo ""
    echo "提示: 将以下内容添加到 ~/.bashrc 或 ~/.zshrc 中以永久生效:"
    echo "source ${PROXY_CONFIG_FILE}"
}

function unset_proxy() {
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    if [ -f "${PROXY_CONFIG_FILE}" ]; then
        rm -f "${PROXY_CONFIG_FILE}"
        echo "✅ 代理配置已清除"
    else
        echo "ℹ️ 未找到代理配置文件"
    fi
}

function show_proxy() {
    echo "=== 当前代理状态 ==="
    if [ -n "${http_proxy}" ]; then
        echo "http_proxy: ${http_proxy}"
        echo "https_proxy: ${https_proxy}"
    elif [ -f "${PROXY_CONFIG_FILE}" ]; then
        echo "代理配置文件: ${PROXY_CONFIG_FILE}"
        echo "状态: 已保存但当前终端未加载"
        echo "执行 source ${PROXY_CONFIG_FILE} 来加载"
    else
        echo "未设置代理"
    fi
}

function load_proxy() {
    if [ -f "${PROXY_CONFIG_FILE}" ]; then
        # shellcheck source=/dev/null
        source "${PROXY_CONFIG_FILE}"
        echo "✅ 已加载保存的代理配置"
    else
        echo "ℹ️ 未找到代理配置文件"
    fi
}

function show_menu() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║           代理管理工具                 ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    show_proxy
    echo ""
    echo "请选择操作:"
    echo "  1. 设置代理"
    echo "  2. 清除代理"
    echo "  3. 加载已保存的代理"
    echo "  4. 显示当前状态"
    echo "  0. 退出"
    echo ""
    read -p "请输入选项 [0-4]: " -n 1 -r
    echo ""
}

while true; do
    show_menu
    
    case "$REPLY" in
        1)
            echo ""
            setup_proxy_interactive
            echo ""
            read -p "按任意键继续..." -n 1 -r
            echo ""
            ;;
        2)
            echo ""
            unset_proxy
            echo ""
            read -p "按任意键继续..." -n 1 -r
            echo ""
            ;;
        3)
            echo ""
            load_proxy
            echo ""
            read -p "按任意键继续..." -n 1 -r
            echo ""
            ;;
        4)
            echo ""
            show_proxy
            echo ""
            read -p "按任意键继续..." -n 1 -r
            echo ""
            ;;
        0)
            echo "退出..."
            exit 0
            ;;
        *)
            echo ""
            echo "❌ 无效选项，请输入 0-4 之间的数字"
            echo ""
            read -p "按任意键继续..." -n 1 -r
            echo ""
            ;;
    esac
done