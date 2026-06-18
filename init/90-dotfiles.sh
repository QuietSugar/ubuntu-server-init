#!/bin/bash

set -e

. ./utils.sh

FLAG_FILE="${HOME}/.zsh/enable"
if [ -e "${FLAG_FILE}" ]; then
    l_skip "dotfiles already installed."
    exit 0
fi

DOTFILES_DIR="$(pwd)/dotfiles"

# 比较两个文件内容是否一致
files_equal() {
    if [ ! -f "$1" ] || [ ! -f "$2" ]; then
        return 1
    fi
    diff -q "$1" "$2" >/dev/null 2>&1
}

# 安装单个 dotfile：copy 或比较
install_dotfile() {
    local src="$1"
    local dst="$2"

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if files_equal "$src" "$dst"; then
            l_skip "$dst already exists and is identical."
        else
            l_warn "$dst already exists and differs from source:"
            diff -u "$dst" "$src" || true
        fi
    else
        cp "$src" "$dst"
        l_success "installed $dst"
    fi
}

l_info "configuring dotfiles..."

# 安装主配置文件
install_dotfile "${DOTFILES_DIR}/zshrc" "${HOME}/.zshrc"
install_dotfile "${DOTFILES_DIR}/p10k.zsh" "${HOME}/.p10k.zsh"

# 安装 zsh/source 下的自定义脚本
if [ -d "${DOTFILES_DIR}/zsh/source" ]; then
    mkdir -p "${HOME}/.zsh/source"
    for src_file in "${DOTFILES_DIR}/zsh/source/"*; do
        if [ -f "$src_file" ]; then
            install_dotfile "$src_file" "${HOME}/.zsh/source/$(basename "$src_file")"
        fi
    done
fi

# 安装 zsh 插件
clone_plugin() {
    local plugin="$1"
    local url="$2"
    local plugin_dir="${HOME}/.zsh/${plugin}"

    if [ -d "$plugin_dir" ]; then
        l_skip "$plugin_dir already exists, skipping clone."
        return 0
    fi

    if git clone --depth=1 "$url" "$plugin_dir" 2>/dev/null; then
        l_success "cloned $plugin"
        return 0
    fi

    rm -rf "$plugin_dir"
    l_warn "failed to clone $plugin, continuing without it"
    return 0
}

clone_plugin powerlevel10k "${P10K_REPO}"
clone_plugin zsh-autosuggestions "${ZSH_AUTOSUGGESTIONS_REPO}"
clone_plugin zsh-syntax-highlighting "${ZSH_SYNTAX_HIGHLIGHTING_REPO}"
clone_plugin zsh-completions "${ZSH_COMPLETIONS_REPO}"

touch "${FLAG_FILE}"
l_success "dotfiles configured."
