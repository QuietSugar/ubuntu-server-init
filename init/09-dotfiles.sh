#!/bin/bash

. ./utils.sh

DOTFILES_DIR="${HOME}/.dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
	l_skip "dotfiles already installed."
else
	l_info "configuring dotfiles..."
    git clone "https://ghproxy.com/https://github.com/QuietSugar/dotfiles" $DOTFILES_DIR > /dev/null 2>&1 
    # 使用rcm管理
    install_via_apt rcm
    git clone --depth=1 https://ghproxy.com/https://github.com/romkatv/powerlevel10k.git ~/.zsh/powerlevel10k
    git clone --depth=1 https://ghproxy.com/https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    git clone --depth=1 https://ghproxy.com/https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
    git clone --depth=1 https://ghproxy.com/https://github.com/zsh-users/zsh-completions.git ~/.zsh/zsh-completions
	env RCRC=$DOTFILES_DIR/rcrc rcup
	l_success "dotfiles configured."
fi
