#!/bin/bash

set -e

. ./utils.sh

# apt 源：优先用 APT_SOURCES_URL（完整基址，如内网 Nexus apt proxy），否则按发行版拼 APT_MIRROR
DISTRIB_CODENAME=$(get_distrib_codename)
if [ -z "${DISTRIB_CODENAME}" ]; then
    l_error "无法获取系统版本代号，跳过 apt 源配置"
    exit 1
fi
DISTRIB_ID=$(get_distrib_id)

if [ -n "${APT_SOURCES_URL:-}" ]; then
    SRC_BASE="${APT_SOURCES_URL}"
    SRC_SEC="${APT_SOURCES_URL}"
    SRC_MARK="${APT_SOURCES_URL}"
elif [ "${DISTRIB_ID}" == "debian" ]; then
    SRC_BASE="https://${APT_MIRROR}/debian"
    SRC_SEC="https://${APT_MIRROR}/debian-security"
    SRC_MARK="aliyun"
else
    SRC_BASE="https://${APT_MIRROR}/ubuntu"
    SRC_SEC="https://${APT_MIRROR}/ubuntu"
    SRC_MARK="aliyun"
fi

if grep -qF "${SRC_MARK}" /etc/apt/sources.list 2>/dev/null; then
    l_skip "apt sources list already configured"
else
    l_info "配置 apt 源 (系统: ${DISTRIB_ID}, 版本: ${DISTRIB_CODENAME}, base: ${SRC_BASE})..."

    if [ "${DISTRIB_ID}" == "debian" ]; then
        sudo tee /etc/apt/sources.list >/dev/null <<EOF
deb ${SRC_BASE} ${DISTRIB_CODENAME} main contrib non-free non-free-firmware
deb-src ${SRC_BASE} ${DISTRIB_CODENAME} main contrib non-free non-free-firmware

deb ${SRC_SEC} ${DISTRIB_CODENAME}-security main contrib non-free non-free-firmware
deb-src ${SRC_SEC} ${DISTRIB_CODENAME}-security main contrib non-free non-free-firmware

deb ${SRC_BASE} ${DISTRIB_CODENAME}-updates main contrib non-free non-free-firmware
deb-src ${SRC_BASE} ${DISTRIB_CODENAME}-updates main contrib non-free non-free-firmware

deb ${SRC_BASE} ${DISTRIB_CODENAME}-backports main contrib non-free non-free-firmware
deb-src ${SRC_BASE} ${DISTRIB_CODENAME}-backports main contrib non-free non-free-firmware
EOF
    else
        sudo tee /etc/apt/sources.list >/dev/null <<EOF
deb ${SRC_BASE} ${DISTRIB_CODENAME} main restricted universe multiverse
deb-src ${SRC_BASE} ${DISTRIB_CODENAME} main restricted universe multiverse

deb ${SRC_SEC} ${DISTRIB_CODENAME}-security main restricted universe multiverse
deb-src ${SRC_SEC} ${DISTRIB_CODENAME}-security main restricted universe multiverse

deb ${SRC_BASE} ${DISTRIB_CODENAME}-updates main restricted universe multiverse
deb-src ${SRC_BASE} ${DISTRIB_CODENAME}-updates main restricted universe multiverse

# deb ${SRC_BASE} ${DISTRIB_CODENAME}-proposed main restricted universe multiverse
# deb-src ${SRC_BASE} ${DISTRIB_CODENAME}-proposed main restricted universe multiverse

deb ${SRC_BASE} ${DISTRIB_CODENAME}-backports main restricted universe multiverse
deb-src ${SRC_BASE} ${DISTRIB_CODENAME}-backports main restricted universe multiverse
EOF
    fi

    l_success "apt sources list configured"
    l_info "apt update"
    sudo -E apt update >/dev/null 2>&1
    if [ "${DO_DIST_UPGRADE:-0}" = "1" ]; then
        l_info "apt dist-upgrade"
        if ! sudo apt dist-upgrade -y; then
            l_warn "apt dist-upgrade failed, continuing initialization"
        fi
    else
        l_skip "默认不执行 dist-upgrade（需要时 DO_DIST_UPGRADE=1）"
    fi
fi

# 处理安装系统的时候设置的源,防止冲突
APT_ORIGINAL_FILE=/etc/apt/sources.list.d/original.list

if [ -s "${APT_ORIGINAL_FILE}" ]; then
    sudo rm -rf "${APT_ORIGINAL_FILE}"
fi
