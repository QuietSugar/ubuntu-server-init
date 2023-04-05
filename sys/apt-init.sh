#!/bin/bash

. ./utils.sh

# 设置阿里云的源

cat /etc/apt/sources.list | grep "aliyun"

if [ $? -ne 0 ] ;then
    sudo cp -rf ../resource/apt.sources.list.20.04 /etc/apt/sources.list
    l_success "apt sources list configured"
else
    l_skip "apt sources list already configured"
fi
