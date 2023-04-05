#!/bin/bash

set -e

. ./utils.sh

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

run_scripts_in_dir term

l_success "done."

printf "\n\n"
print_logo
