#!/bin/bash
# 可选：安装 hall-kit 工具箱（在 ubuntu-server-init 之后手动执行）
# 重复执行会把 hall-kit 及其命令更新到最新（这里用 install_via_go ... update）
#
# 直连 GitHub 不可用时，先设置 GOPROXY，例如：
#   go env -w GOPROXY=https://goproxy.cn,direct
# 或用标准代理：export https_proxy=http://host:port

set -e

. ./config.sh
. ./utils.sh

if ! command -v go &> /dev/null; then
    l_error "command go not found. 请先执行 'bash dev-env.sh'（用 vfox 安装 golang）"
    exit 1
fi

GO_BIN_DIR="$(go env GOBIN)"
if [ -z "${GO_BIN_DIR}" ]; then
    GO_BIN_DIR="$(go env GOPATH)/bin"
fi

HALL_KIT_VERSION="${HALL_KIT_VERSION:-latest}"
l_info "GOPROXY=$(go env GOPROXY)"
l_info "hall-kit version: ${HALL_KIT_VERSION}（用 HALL_KIT_VERSION 覆盖；调试建议填 commit sha）"

for cmd in hall gitcheck gitclone gitarc rmempty dockerage; do
    install_via_go "github.com/QuietSugar/hall-kit/cmd/${cmd}@${HALL_KIT_VERSION}" update
done

l_info "installing hall shell assets..."
"${GO_BIN_DIR}/hall" shell install

l_success "hall-kit installed. 重新打开 shell 后可用 proxy/tat 等。"
