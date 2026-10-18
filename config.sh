#!/bin/bash

# 镜像源配置
export APT_MIRROR="${APT_MIRROR:-mirrors.aliyun.com}"
export DOCKER_MIRROR="${DOCKER_MIRROR:-mirrors.aliyun.com}"

# 可选：完整 apt 源基址覆盖（例如内网 Nexus 的 apt proxy 仓库）
# 留空 = 用 APT_MIRROR 拼 https://<mirror>/ubuntu 或 /debian
# 例：http://<nexus-host>/repository/apt--proxy-jammy
export APT_SOURCES_URL="${APT_SOURCES_URL:-}"

# 可选：docker 的 apt 源覆盖（deb 行与 gpg 都从这里取）
# 留空 = 用 DOCKER_MIRROR 拼 https://<mirror>/docker-ce/linux/<distro>
# 例：http://<nexus-host>/repository/apt--proxy-docker
export DOCKER_APT_URL="${DOCKER_APT_URL:-}"

# GitHub 加速：GH_PROXY 显式覆盖时会跳过自动探测；留空则自动探测（见 utils.sh 的 gh_url/detect_gh_proxy）
# GH_PROXY_AUTO=0 可关闭自动探测（强制直连）；GH_PROXY_AUTO_LIST 为候选加速站
export GH_PROXY_AUTO="${GH_PROXY_AUTO:-1}"
export GH_PROXY_AUTO_LIST="${GH_PROXY_AUTO_LIST:-https://gh-proxy.com/ https://ghfast.top/}"
# vfox 配置
export VFOX_VERSION="${VFOX_VERSION:-v1.0.11}"
export VFOX_APT_REPO="${VFOX_APT_REPO:-apt.fury.io/versionfox}"
export VFOX_GITHUB_REPO="${VFOX_GITHUB_REPO:-version-fox/vfox}"

# zsh 插件仓库
export P10K_REPO="${P10K_REPO:-https://github.com/romkatv/powerlevel10k.git}"
export ZSH_AUTOSUGGESTIONS_REPO="${ZSH_AUTOSUGGESTIONS_REPO:-https://github.com/zsh-users/zsh-autosuggestions.git}"
export ZSH_SYNTAX_HIGHLIGHTING_REPO="${ZSH_SYNTAX_HIGHLIGHTING_REPO:-https://github.com/zsh-users/zsh-syntax-highlighting.git}"
export ZSH_COMPLETIONS_REPO="${ZSH_COMPLETIONS_REPO:-https://github.com/zsh-users/zsh-completions.git}"

# z.sh
export Z_SH_URL="${Z_SH_URL:-https://raw.githubusercontent.com/rupa/z/master/z.sh}"

# hall-kit（Go 工具）安装版本
# 默认 latest；频繁调试时建议指定 main / 分支 / tag / commit 伪版本，
# 避开 GOPROXY 与本地 module cache 对 @latest 的缓存。
export HALL_KIT_VERSION="${HALL_KIT_VERSION:-latest}"

# 测试/调试开关
# SKIP_STEPS：main.sh 跳过指定的 init 步骤（按文件名，空格分隔）
#   例：SKIP_STEPS="01-apt-init.sh" bash main.sh
# DO_DIST_UPGRADE=1：01-apt-init.sh 额外执行 apt dist-upgrade（默认 0 = 不升级整个系统）
export SKIP_STEPS="${SKIP_STEPS:-}"
export DO_DIST_UPGRADE="${DO_DIST_UPGRADE:-0}"
