#!/bin/bash

set -e

LOCAL_PROXY_SCRIPT="${ROOT_DIR}/init/http_proxy_set.sh"
REMOTE_PROXY_URL="https://raw.githubusercontent.com/QuietSugar/hall-command/refs/heads/master/command/http_proxy_set.sh"
TARGET_DIR="${HOME}/.hall-command/command/source"
TARGET_FILE="${TARGET_DIR}/http_proxy_set.sh"

function update_proxy_script() {
    echo "正在检查并更新代理脚本..."
    
    mkdir -p "${TARGET_DIR}"
    
    if curl -fsSL -o "${TARGET_FILE}.tmp" "${REMOTE_PROXY_URL}"; then
        if [ -f "${TARGET_FILE}" ]; then
            if diff -q "${TARGET_FILE}" "${TARGET_FILE}.tmp" >/dev/null 2>&1; then
                echo "代理脚本已是最新版本"
                rm -f "${TARGET_FILE}.tmp"
            else
                mv "${TARGET_FILE}.tmp" "${TARGET_FILE}"
                echo "代理脚本已更新"
            fi
        else
            mv "${TARGET_FILE}.tmp" "${TARGET_FILE}"
            echo "代理脚本已下载"
        fi
        return 0
    else
        echo "无法从远程获取代理脚本"
        rm -f "${TARGET_FILE}.tmp"
        return 1
    fi
}

function setup_proxy_from_local() {
    if [ -f "${LOCAL_PROXY_SCRIPT}" ]; then
        # shellcheck source=/dev/null
        if source "${LOCAL_PROXY_SCRIPT}" 2>/dev/null && command -v setup_proxy >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

function setup_proxy_from_remote() {
    if [ -f "${TARGET_FILE}" ]; then
        # shellcheck source=/dev/null
        if source "${TARGET_FILE}" 2>/dev/null && command -v setup_proxy >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

if [ "${UPDATE_PROXY_SCRIPT}" = "true" ]; then
    update_proxy_script
    exit $?
fi

if [ -z "${ENABLE_PROXY_SETUP}" ] || [ "${ENABLE_PROXY_SETUP}" != "true" ]; then
    exit 0
fi

if setup_proxy_from_local; then
    read -p "是否设置 HTTP/HTTPS 代理? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_proxy
    else
        echo "跳过代理设置"
    fi
elif setup_proxy_from_remote; then
    read -p "是否设置 HTTP/HTTPS 代理? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_proxy
    else
        echo "跳过代理设置"
    fi
else
    echo "无法加载代理设置脚本"
    read -p "是否尝试更新代理脚本? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if update_proxy_script && setup_proxy_from_remote; then
            read -p "是否设置 HTTP/HTTPS 代理? [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                setup_proxy
            else
                echo "跳过代理设置"
            fi
        else
            echo "更新代理脚本失败"
        fi
    fi
fi
