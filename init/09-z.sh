#!/bin/bash

set -e

. ./utils.sh

Z_SH_DIR="${HOME}/.zsh/source"
mkdir -p "${Z_SH_DIR}"
Z_SH_FILE="${Z_SH_DIR}/z.sh"

if [ ! -s "${Z_SH_FILE}" ]; then
	l_info "configuring z..."
	if fetch "${Z_SH_FILE}" "${Z_SH_URL}"; then
		l_success "z configured."
	else
		l_warn "failed to download z, continuing without it"
	fi
else
	l_skip "z already installed."
fi
