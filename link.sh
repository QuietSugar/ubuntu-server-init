#!/bin/bash

[ -f "INFO" ] && [ "$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//' .gitkeep)" = "UBUNTU-SERVER-INIT" ] || { echo "不是预期目录"; exit 1; }

if ! command -v git &> /dev/null; then
    echo "错误: 系统中未安装 git 命令"
    exit 1
fi

if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "当前目录已处于 git 管理之下，退出"
    exit 1
fi

# 检查远程仓库是否网络可达
if ! curl -s --connect-timeout 1 https://github.com/QuietSugar/ubuntu-server-init.git > /dev/null; then
    echo "错误: 远程仓库 https://github.com/QuietSugar/ubuntu-server-init.git 不可达"
    exit 1
fi

# 初始化 git 仓库并关联远程仓库
# 检查是否存在代理设置
if [[ -n "$https_proxy" || -n "$HTTPS_PROXY" ]]; then
    GIT_PROXY_CONFIG="-c http.proxy=$https_proxy"
elif [[ -n "$http_proxy" || -n "$HTTP_PROXY" ]]; then
    GIT_PROXY_CONFIG="-c http.proxy=$http_proxy"
else
    GIT_PROXY_CONFIG=""
fi

# 使用初始化和拉取命令时加入代理配置（如有）
git init
git remote add origin https://github.com/QuietSugar/ubuntu-server-init.git

# 应用重置与清理操作
git reset --hard
git clean -fd

# 根据是否有代理决定如何执行 pull
if [ -n "$GIT_PROXY_CONFIG" ]; then
    git $GIT_PROXY_CONFIG pull origin master
else
    git pull origin master
fi

git status
