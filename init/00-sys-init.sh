#!/bin/bash

set -e

. ./utils.sh

# 移除多路径服务 multipath-tools
if systemctl status multipathd.service >/dev/null 2>&1; then
    echo "multipathd is installed"
    if systemctl is-active multipathd.service >/dev/null 2>&1; then
        echo "multipathd is running"
    else
        echo "multipathd is installed but not running"
    fi
    sudo systemctl stop multipathd || true
    sudo systemctl disable multipathd || true
    sudo apt remove -y multipath-tools
else
    echo "multipathd is not installed"
fi

# 移除snap
if dpkg-query -s snapd >/dev/null 2>&1; then
    echo "snap is installed"
    if snap list lxd >/dev/null 2>&1; then
        sudo snap remove lxd
    fi
    if snap list core20 >/dev/null 2>&1; then
        sudo snap remove core20
    fi
    sudo snap remove snapd
    # 卸载 Snap 和相关文件
    sudo apt autoremove -y --purge snapd
else
    echo "snap is not installed"
fi

