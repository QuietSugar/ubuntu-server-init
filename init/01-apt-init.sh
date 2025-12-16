#!/bin/bash

. ./utils.sh

# 设置阿里云的源
cat /etc/apt/sources.list | grep "aliyun" >/dev/null
if [ $? -ne 0 ]; then
    cat ./resource/apt.sources.list.20.04 | sudo tee /etc/apt/sources.list >/dev/null
    l_success "apt sources list configured"
    #更新源列表
    l_info "apt -E update"
    sudo -E apt update >/dev/null 2>&1
    l_info "apt dist-upgrade"
    sudo apt dist-upgrade -y
else
    l_skip "apt sources list already configured"
fi

# 处理安装系统的时候设置的源,防止冲突
APT_ORIGINAL_FILE=/etc/apt/sources.list.d/original.list

if [ -s "${APT_ORIGINAL_FILE}" ]; then
    sudo rm -rf ${APT_ORIGINAL_FILE}
    # sudo mv ${APT_ORIGINAL_FILE} ${APT_ORIGINAL_FILE}'-back'
fi


