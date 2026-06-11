#!/bin/bash

PROXY_CONFIG_FILE="${HOME}/.proxy_config"

function setup_proxy() {
    echo "=== HTTP/HTTPS 代理设置 ==="
    
    read -p "请输入代理服务器地址 (如: 127.0.0.1): " PROXY_HOST
    if [ -z "$PROXY_HOST" ]; then
        echo "代理地址不能为空"
        return 1
    fi
    
    read -p "请输入代理端口 (如: 7890): " PROXY_PORT
    if [ -z "$PROXY_PORT" ]; then
        echo "代理端口不能为空"
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
    
    echo "代理配置已保存到 ${PROXY_CONFIG_FILE}"
    echo "请在终端中执行: source ${PROXY_CONFIG_FILE} 来应用代理设置"
    echo "或者将以下内容添加到 ~/.bashrc 或 ~/.zshrc 中:"
    echo "source ${PROXY_CONFIG_FILE}"
}

function unset_proxy() {
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    if [ -f "${PROXY_CONFIG_FILE}" ]; then
        rm -f "${PROXY_CONFIG_FILE}"
        echo "代理配置已清除"
    else
        echo "未找到代理配置文件"
    fi
}

function show_proxy() {
    if [ -n "${http_proxy}" ]; then
        echo "当前代理设置:"
        echo "http_proxy: ${http_proxy}"
        echo "https_proxy: ${https_proxy}"
    elif [ -f "${PROXY_CONFIG_FILE}" ]; then
        echo "代理配置文件存在于: ${PROXY_CONFIG_FILE}"
        echo "但当前终端未加载"
    else
        echo "未设置代理"
    fi
}
