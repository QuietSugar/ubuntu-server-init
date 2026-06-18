#!/bin/bash

set -e
# set -x

. ./utils.sh

# 尝试加载或询问 GitHub 代理配置
load_or_ask_github_proxy

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

run_scripts_in_dir init

l_success "done."

printf "\n\n"
print_logo
