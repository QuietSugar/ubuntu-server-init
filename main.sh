#!/bin/bash

set -e
# set -x

. ./utils.sh
. ./dotfiles/zsh/source/http_proxy_set.sh

setup_proxy

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

run_scripts_in_dir init

l_success "done."

printf "\n\n"
print_logo
