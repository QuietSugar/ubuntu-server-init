#!/bin/bash

# 镜像源配置
export APT_MIRROR="${APT_MIRROR:-mirrors.aliyun.com}"
export DOCKER_MIRROR="${DOCKER_MIRROR:-mirrors.aliyun.com}"

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
