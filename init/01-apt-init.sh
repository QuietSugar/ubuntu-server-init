#!/bin/bash

set -e

. ./utils.sh

# 设置阿里云的源
if ! grep -q "aliyun" /etc/apt/sources.list 2>/dev/null; then
    DISTRIB_CODENAME=$(get_distrib_codename)
    if [ -z "${DISTRIB_CODENAME}" ]; then
        l_error "无法获取系统版本代号，跳过 apt 源配置"
        exit 1
    fi

    l_info "配置阿里云 apt 源 (版本: ${DISTRIB_CODENAME})..."

    sudo tee /etc/apt/sources.list >/dev/null <<EOF
deb https://mirrors.aliyun.com/ubuntu/ ${DISTRIB_CODENAME} main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ ${DISTRIB_CODENAME} main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ ${DISTRIB_CODENAME}-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ ${DISTRIB_CODENAME}-security main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ ${DISTRIB_CODENAME}-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ ${DISTRIB_CODENAME}-updates main restricted universe multiverse

# deb https://mirrors.aliyun.com/ubuntu/ ${DISTRIB_CODENAME}-proposed main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ ${DISTRIB_CODENAME}-proposed main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ ${DISTRIB_CODENAME}-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ ${DISTRIB_CODENAME}-backports main restricted universe multiverse
EOF

    l_success "apt sources list configured"
    l_info "apt update"
    sudo -E apt update >/dev/null 2>&1
    l_info "apt dist-upgrade"
    sudo apt dist-upgrade -y
else
    l_skip "apt sources list already configured"
fi

# 处理安装系统的时候设置的源,防止冲突
APT_ORIGINAL_FILE=/etc/apt/sources.list.d/original.list

if [ -s "${APT_ORIGINAL_FILE}" ]; then
    sudo rm -rf "${APT_ORIGINAL_FILE}"
fi


