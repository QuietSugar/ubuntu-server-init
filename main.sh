#!/bin/bash

set -e
# set -x

. ./utils.sh

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

# 处理命令行参数
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --with-proxy|-p)
            ENABLE_PROXY_SETUP="true"
            export ENABLE_PROXY_SETUP
            ;;
        --update-proxy|-u)
            UPDATE_PROXY_SCRIPT="true"
            export UPDATE_PROXY_SCRIPT
            ;;
        *)
            l_error "未知参数: $1"
            exit 1
            ;;
    esac
    shift
done

run_scripts_in_dir init

if [ $? -ne 0 ]; then
    l_warn "部分脚本执行失败"
    l_info "如果是网络问题，可以尝试使用代理模式: bash main.sh --with-proxy"
fi

l_success "done."

printf "\n\n"
print_logo
