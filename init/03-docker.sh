#!/bin/bash

. ./utils.sh



DOCKER_KEY_FILE=/etc/apt/keyrings/docker.gpg
DOCKER_SOURCE_LIST_FILE=/etc/apt/sources.list.d/docker.list

if [ ! -s "${DOCKER_KEY_FILE}" ]; then
    l_info "installing gpg key..."
    sudo mkdir -m 0755 -p /etc/apt/keyrings

    # https://download.docker.com/linux/ubuntu/gpg
    curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
else
    l_skip "docker key file already installed."
fi

if [ ! -s "${DOCKER_SOURCE_LIST_FILE}" ]; then
    l_info "installing docker repository source..."
    DISTRIB_CODENAME=$(get_distrib_codename)
    if [ -z "${DISTRIB_CODENAME}" ]; then
        l_error "DISTRIB_CODENAME is empty."
    else
        # 参考 https://developer.aliyun.com/mirror/docker-ce/?spm=a2c6h.25603864.0.0.2edd7610j7vsQ9
        sudo echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=${DOCKER_KEY_FILE}] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu \
        ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo -E apt update

        # 开始安装
        # sudo apt remove docker docker-engine docker.io containerd runc
        install_via_apt apt-transport-https
        install_via_apt ca-certificates
        install_via_apt curl
        install_via_apt gnupg2
        install_via_apt software-properties-common

        install_via_apt docker-ce
        install_via_apt docker-ce-cli
        install_via_apt containerd.io
        install_via_apt docker-buildx-plugin
        install_via_apt docker-compose-plugin
        # 添加用户到docker组
        sudo gpasswd -a $(whoami) docker
        l_info "use docker first , please reboot machine..."
    fi
else
    l_skip "docker repsoitory source already installed."
fi
