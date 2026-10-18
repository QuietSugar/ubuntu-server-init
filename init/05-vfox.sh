#!/bin/bash

set -e

. ./utils.sh

if command -v vfox &> /dev/null; then
    l_skip "vfox already installed"
else
    ARCH=$(dpkg --print-architecture)
    case "${ARCH}" in
        arm64)
            VFOX_ARCH="aarch64"
            ;;
        amd64)
            VFOX_ARCH="x86_64"
            ;;
        armhf)
            VFOX_ARCH="armv7"
            ;;
        i386)
            VFOX_ARCH="i386"
            ;;
        *)
            VFOX_ARCH="${ARCH}"
            ;;
    esac

    # 优先尝试 apt 源安装
    if curl -fsSL --connect-timeout 5 --max-time 10 "https://${VFOX_APT_REPO}/" >/dev/null 2>&1; then
        echo "deb [trusted=yes] https://${VFOX_APT_REPO}/ /" | sudo tee /etc/apt/sources.list.d/versionfox.list
        sudo -E apt update
        sudo -E apt install -y vfox
    else
        l_warn "apt.fury.io is unreachable, installing vfox from GitHub release..."
        DEB_URL="https://github.com/${VFOX_GITHUB_REPO}/releases/download/${VFOX_VERSION}/vfox_${VFOX_VERSION#v}_linux_${VFOX_ARCH}.deb"
        if ! install_remote_deb "${DEB_URL}" vfox; then
            l_warn "vfox installation failed, continuing initialization"
            exit 0
        fi
    fi
    l_success "vfox installed"
fi
