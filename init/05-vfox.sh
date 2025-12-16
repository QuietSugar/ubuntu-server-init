#!/bin/bash
. ./utils.sh

if command -v vfox &> /dev/null; then
    l_skip "vfox already installed"
else
  echo "deb [trusted=yes] https://apt.fury.io/versionfox/ /" | sudo tee /etc/apt/sources.list.d/versionfox.list
  sudo -E apt update
  sudo -E apt install vfox
  l_success "vfox installed"
fi





