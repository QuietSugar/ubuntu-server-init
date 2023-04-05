#!/bin/bash

. ./utils.sh

PROFILE_FILE="${HOME}/.profile"

source $PROFILE_FILE

# Install pyenv
command -v pyenv &> /dev/null
if [ $? != 0 ]; then
	curl https://pyenv.run | bash

	cat <<-EOF >> $PROFILE_FILE
	export PYENV_ROOT="\$HOME/.pyenv"
	command -v pyenv >/dev/null || export PATH="\$PYENV_ROOT/bin:\$PATH"
	eval "\$(pyenv init -)"
EOF
	source $PROFILE_FILE
	l_success "$(pyenv --version) installed."
else
	l_skip "$(pyenv --version) already installed."
fi

# Install python via pyenv
command -v python &> /dev/null
if [ $? != 0 ]; then
	PYTHON_VESION=3.11.2
	pyenv install "${PYTHON_VESION}"
	pyenv rehash
	pyenv global "${PYTHON_VESION}"
	l_success "$(python --version) installed."
else
	l_skip "$(python --version) already installed."
fi
 
 