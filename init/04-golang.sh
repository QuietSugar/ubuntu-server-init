#!/bin/bash

# eg: https://studygolang.com/dl/golang/go1.21.5.linux-amd64.tar.gz
# eg: https://go.dev/dl/go1.19.7.linux-amd64.tar.gz
# 检查是否传递了参数
if [ -z "$1" ]; then
    # 如果未传递参数，设置默认值
    THIS_GO_VERSION="1.21.5"
else
    # 如果传递了参数，将其存储在变量中
    THIS_GO_VERSION=$1
fi
. ./utils.sh

THIS_GO_DIR="${HOME}/working/soft/go-${THIS_GO_VERSION}"
mkdir -p $THIS_GO_DIR
THIS_GO_BIN_FILE_PATH="${THIS_GO_DIR}/go/bin/go"
THIS_GO_BIN_DIR_PATH="${THIS_GO_DIR}/go/bin"
# go安装的命令的PATH
GO_PKG_BIN_DIR_PATH="${HOME}/go/bin"

GO_PROFILE="${HOME}/.xu/source/go.profile.sh"

# Install golang
# 支持的版本
command -v ${THIS_GO_BIN_FILE_PATH} > /dev/null
if [ $? != 0 ]; then
	l_info "installing golang...$THIS_GO_VERSION"
	http --download https://go.dev/dl/go${THIS_GO_VERSION}.linux-amd64.tar.gz -o go.tar.gz
	sudo tar -C ${THIS_GO_DIR} -xzf go.tar.gz
	sudo chmod a+x ${THIS_GO_BIN_FILE_PATH}
	echo 'export PATH=$PATH:'${THIS_GO_BIN_DIR_PATH}':'${GO_PKG_BIN_DIR_PATH} > "${GO_PROFILE}"
	source "${GO_PROFILE}"
	l_success "golang $(go version) installed."
	rm -f go.tar.gz
else
	l_skip "golang $(go version) already installed"
fi
