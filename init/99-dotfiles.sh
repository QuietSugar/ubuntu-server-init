#!/bin/bash

# 初始化了配置文件

. ./utils.sh

DOTFILES_DIR="$(pwd)/dotfiles"
echo $DOTFILES_DIR
FLAG_FILE="${HOME}/.zshrc"
if [ -s "${FLAG_FILE}" ]; then
	l_skip "dotfiles already installed."
else
	l_info "configuring dotfiles..."
  # 使用rcm管理
  install_via_apt rcm
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh/powerlevel10k
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
  git clone --depth=1 https://github.com/zsh-users/zsh-completions.git ~/.zsh/zsh-completions
	env RCRC=$DOTFILES_DIR/rcrc rcup -d $DOTFILES_DIR
	l_success "dotfiles configured."
fi
