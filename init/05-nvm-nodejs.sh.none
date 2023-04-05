#!/bin/bash

. ./utils.sh

PROFILE_FILE="${HOME}/.profile"

source $PROFILE_FILE

# Install nvm and nodejs
if [ -z "$NVM_DIR" ]; then
	l_info "installing nvm"
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
	source "${PROFILE_FILE}"
    l_success "$(nvm --version) installed."
else
	. ${NVM_DIR}/nvm.sh
	l_skip "nvm $(nvm --version) already installed."
fi

# Install lastest Node.js
command -v node &> /dev/null 
if [ $? != 0 ]; then
	nvm install --lts --default
	corepack enable
	l_success "$(node --version) installed."
else
	l_skip "node $(node --version) already installed."
fi
