#!/bin/bash
. ./utils.sh

# http工具： xh 可以替换 httpie

if command -v xh &> /dev/null; then
    l_skip "xh already installed"
    exit 0
fi

releases=$(fetch https://api.github.com/repos/ducaale/xh/releases/latest)
url=$(echo "$releases" | grep -wo -m1 "https://.*x86_64-unknown-linux-musl.tar.gz" || true)
if ! test "$url"; then
    echo "Could not find release info"
    exit 1
fi

echo "Downloading xh..."

temp_dir=$(mktemp -dt xh.XXXXXX)
trap 'rm -rf "$temp_dir"' EXIT INT TERM
cd "$temp_dir"

if ! fetch xh.tar.gz "$url"; then
    echo "Could not download tarball"
    exit 1
fi

tar xzf xh.tar.gz
xh_installdir="/usr/local/bin"
sudo mv xh-*/xh "$xh_installdir/"
xh_file_path="$xh_installdir"/xh
xh_version=$("$xh_file_path" -V)

l_success "${xh_version} has been installed to:"
l_success " • ${xh_file}"




