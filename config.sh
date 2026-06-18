#!/bin/bash

# 镜像源配置
APT_MIRROR="${APT_MIRROR:-mirrors.aliyun.com}"
DOCKER_MIRROR="${DOCKER_MIRROR:-mirrors.aliyun.com}"

# vfox 配置
VFOX_VERSION="${VFOX_VERSION:-v1.0.11}"
VFOX_APT_REPO="${VFOX_APT_REPO:-apt.fury.io/versionfox}"
VFOX_GITHUB_REPO="${VFOX_GITHUB_REPO:-version-fox/vfox}"

# zsh 插件仓库
P10K_REPO="${P10K_REPO:-https://github.com/romkatv/powerlevel10k.git}"
ZSH_AUTOSUGGESTIONS_REPO="${ZSH_AUTOSUGGESTIONS_REPO:-https://github.com/zsh-users/zsh-autosuggestions.git}"
ZSH_SYNTAX_HIGHLIGHTING_REPO="${ZSH_SYNTAX_HIGHLIGHTING_REPO:-https://github.com/zsh-users/zsh-syntax-highlighting.git}"
ZSH_COMPLETIONS_REPO="${ZSH_COMPLETIONS_REPO:-https://github.com/zsh-users/zsh-completions.git}"

# z.sh
Z_SH_URL="${Z_SH_URL:-https://raw.githubusercontent.com/rupa/z/master/z.sh}"
