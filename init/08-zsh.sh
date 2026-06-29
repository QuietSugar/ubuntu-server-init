#!/bin/bash

. ./utils.sh

install_via_apt zsh

CURRENT_SHELL=$(getent passwd "$(whoami)" | cut -d: -f7)

if [ "$CURRENT_SHELL" == "$(which zsh)" ]; then
	l_skip "default shell of current user already set to zsh"
else
	chsh -s $(which zsh)
	l_success "set zsh as default."
fi

