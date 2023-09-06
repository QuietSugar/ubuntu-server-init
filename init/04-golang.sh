#!/bin/bash

. ./utils.sh

PROFILE_FILE="${HOME}/.profile"
GO_PATH_DIR="${HOME}/working/soft/go"
exit 1
source $PROFILE_FILE

# Install golang
command -v go > /dev/null
if [ $? != 0 ]; then
	l_info "installing golang..."
	http --download https://go.dev/dl/go1.19.7.linux-amd64.tar.gz -o go.tar.gz
	sudo tar -C /usr/local -xzf go.tar.gz
	sudo chmod a+x /usr/local/go/bin/go
	echo 'export PATH=$PATH:/usr/local/go/bin' >> "${PROFILE_FILE}"
  echo "export GOPATH=${GO_PATH_DIR}" >> "${PROFILE_FILE}"
	source "${PROFILE_FILE}"
	l_success "golang $(go version) installed."
	rm -f go.tar.gz
else
	l_skip "golang $(go version) already installed"
fi
