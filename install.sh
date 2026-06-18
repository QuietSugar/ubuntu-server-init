#!/bin/bash

set -e

UBUNTU_SERVER_INIT_DIR="${HOME}/.local/share/ubuntu-server-init"
PROXY_CONFIG_FILE="${HOME}/.config/ubuntu-server-init/proxy"

save_proxy_config(){
    local proxy_url="$1"
    mkdir -p "$(dirname "${PROXY_CONFIG_FILE}")"
    cat > "${PROXY_CONFIG_FILE}" <<EOF
export http_proxy="${proxy_url}"
export https_proxy="${proxy_url}"
export HTTP_PROXY="${proxy_url}"
export HTTPS_PROXY="${proxy_url}"
EOF
}

load_proxy_config(){
    if [ -f "${PROXY_CONFIG_FILE}" ]; then
        # shellcheck source=/dev/null
        source "${PROXY_CONFIG_FILE}"
    fi
}

load_or_ask_proxy(){
    if [ -n "${https_proxy}" ] || [ -n "${HTTPS_PROXY}" ]; then
        return 0
    fi

    load_proxy_config

    if [ -n "${https_proxy}" ] || [ -n "${HTTPS_PROXY}" ]; then
        if [ -t 0 ]; then
            read -rp "Use saved proxy '${https_proxy:-${HTTPS_PROXY}}'? [Y/n]: " answer
            case "${answer}" in
                n|N)
                    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
                    ;;
                *)
                    return 0
                    ;;
            esac
        else
            return 0
        fi
    fi

    if [ -t 0 ]; then
        read -rp "Enter HTTP/HTTPS proxy (e.g. http://192.168.1.100:7890, press Enter to skip): " proxy_url
        if [ -n "${proxy_url}" ]; then
            save_proxy_config "${proxy_url}"
            load_proxy_config
        fi
    fi
}

fetch(){
    if which curl > /dev/null; then
        if [ "$#" -eq 2 ]; then curl -fL --connect-timeout 10 --max-time 60 --retry 2 -o "$1" "$2"; else curl -fsSL --connect-timeout 10 --max-time 60 --retry 2 "$1"; fi
    elif which wget > /dev/null; then
        if [ "$#" -eq 2 ]; then wget --timeout=60 --tries=3 -O "$1" "$2"; else wget --timeout=60 --tries=3 -nv -O - "$1"; fi
    else
        echo "Can't find curl or wget, can't download package"
        exit 1
    fi
}

get_latest_release_url(){
    if [ -n "${RELEASE_FILE_URL}" ]; then
        echo "${RELEASE_FILE_URL}"
    else
        echo "https://codeload.github.com/QuietSugar/ubuntu-server-init/zip/refs/heads/dev"
    fi
}
download_and_un_tar(){
  url=$(get_latest_release_url)
  if ! test "$url"; then
      echo "Could not find release info"
      exit 1
  fi
  echo "Downloading ubuntu-server-init..."

  temp_dir=$(mktemp -dt ubuntu-server-init.XXXXXX)
  trap 'rm -rf "$temp_dir"' EXIT INT TERM
  cd "$temp_dir"

  if ! fetch ubuntu-server-init.zip "$url"; then
      echo "Could not download "
      exit 1
  fi
  unzip ubuntu-server-init.zip
  rm ubuntu-server-init.zip
  mkdir -p "$(dirname "${UBUNTU_SERVER_INIT_DIR}")"
  mv ubuntu-server-init* "${UBUNTU_SERVER_INIT_DIR}"
}

main(){
  if [ -d "${UBUNTU_SERVER_INIT_DIR}" ]; then
    echo "安装目录已存在: ${UBUNTU_SERVER_INIT_DIR}"
  else
    load_or_ask_proxy
    download_and_un_tar
    cd "${UBUNTU_SERVER_INIT_DIR}"
    bash main.sh
  fi
}

main


