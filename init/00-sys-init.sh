#!/bin/bash

. ./utils.sh

# 移除多路径服务 multipath-tools

if systemctl status multipathd.service >/dev/null 2>&1; then
    echo "multipathd is installed"
    if systemctl is-active multipathd.service >/dev/null 2>&1; then
        echo "multipathd is running"
    else
        echo "multipathd is installed but not running"
    fi
    sudo systemctl stop multipathd
    sudo systemctl disable multipathd
    sudo apt-get remove -y multipath-tools
    # 或者
    # sudo apt-get purge multipath-tools
else
    echo "multipathd is not installed"
fi

# 移除snap
# 列出已安装的所有 Snap 软件包，并循环卸载每个软件包
# for package in $(snap list | awk '{if(NR>1)print $1}'); do
#     sudo snap remove $package
# done

# 上述服务会有依赖关系,所以没法循环卸载,所以还是一个一个卸载

if dpkg-query -s snapd >/dev/null 2>&1; then
    echo "snap is installed"
    sudo snap remove lxd
    sudo snap remove core20
    sudo snap remove snapd
    # 卸载 Snap 和相关文件
    sudo apt autoremove -y --purge snapd
else
    echo "snap is not installed"
fi
