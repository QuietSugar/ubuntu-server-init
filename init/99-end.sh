#!/bin/bash

. ./utils.sh
l_info "apt autoremove"
sudo -E apt autoremove

l_info "请重新打开shell"
l_info "you can install golang java maven nodejs by 'bash init/dev.sh.manual'"
