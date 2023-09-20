#!/bin/bash

. ./utils.sh

ZSHRC_FILE="${HOME}/.zshrc"
mkdir -p "${HOME}/init"
Z_SH_File="${HOME}/init/z.sh"

if [ ! -s "${Z_SH_File}" ]; then
	l_info "configuring z..."
	http --download https://ghproxy.com/https://raw.githubusercontent.com/rupa/z/master/z.sh -o ${Z_SH_File}
	echo "source ${Z_SH_File}" >> "${ZSHRC_FILE}"
	l_success "z configured."
else
	l_skip "z already installed."
fi
