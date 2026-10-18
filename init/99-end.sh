#!/bin/bash

set -e

. ./utils.sh
l_info "如需清理无用依赖，可手动执行: sudo apt autoremove"
l_info "请重新打开shell"
l_info "you can install golang java maven nodejs by 'bash dev-env.sh' (optional, large downloads)"
l_info "you can install hall-kit by 'bash hall-kit.sh' (optional)"
