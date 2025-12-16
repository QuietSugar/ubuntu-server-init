#!/bin/bash

# 初始化了配置文件

. ./utils.sh

FLAG_FILE="${HOME}/.zsh/enable"
echo $FLAG_FILE
if [ -e "${FLAG_FILE}" ]; then
	l_skip "dotfiles already installed."
else
	l_info "configuring dotfiles..."
	if [ -s "${HOME}/.zshrc" ]; then
  	l_info "backup .zshrc file."
  	mv "${HOME}/.zshrc" "${HOME}/.zshrc.bak"
  fi
  # 使用rcm管理
  install_via_apt rcm
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh/powerlevel10k
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
  git clone --depth=1 https://github.com/zsh-users/zsh-completions.git ~/.zsh/zsh-completions
  DOTFILES_DIR="$(pwd)/dotfiles"
	env RCRC=$DOTFILES_DIR/rcrc rcup -d $DOTFILES_DIR
	touch "${FLAG_FILE}"
	l_success "dotfiles configured."
fi
