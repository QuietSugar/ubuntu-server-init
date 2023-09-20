#!/bin/bash

. ./utils.sh

ZSHRC_FILE="${HOME}/.zshrc"
Z_SH_DIR="${HOME}/working/soft/z"
mkdir -p "${Z_SH_DIR}"
Z_SH_FILE="${Z_SH_DIR}/z.sh"

if [ ! -s "${Z_SH_FILE}" ]; then
	l_info "configuring z..."
	http --download https://ghproxy.com/https://raw.githubusercontent.com/rupa/z/master/z.sh -o ${Z_SH_FILE}
  # 由zshrc管理
  #	echo "source ${Z_SH_FILE}" >> "${ZSHRC_FILE}"
	l_success "z configured."
else
	l_skip "z already installed."
fi
