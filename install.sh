#!/bin/bash

set -e

UBUNTU_SERVER_INIT_DIR="${HOME}/.local/share/ubuntu-server-init"
GITHUB_PROXY_CONFIG_FILE="${HOME}/.config/ubuntu-server-init/github_proxy"

load_or_ask_github_proxy(){
    if [ -n "${GITHUB_PROXY}" ]; then
        return 0
    fi

    if [ -f "${GITHUB_PROXY_CONFIG_FILE}" ]; then
        local saved_proxy
        saved_proxy=$(cat "${GITHUB_PROXY_CONFIG_FILE}")
        if [ -n "${saved_proxy}" ]; then
            if [ -t 0 ]; then
                read -rp "Use saved GitHub proxy '${saved_proxy}'? [Y/n]: " answer
                case "${answer}" in
                    n|N)
                        ;;
                    *)
                        export GITHUB_PROXY="${saved_proxy}"
                        return 0
                        ;;
                esac
            else
                export GITHUB_PROXY="${saved_proxy}"
                return 0
            fi
        fi
    fi

    if [ -t 0 ]; then
        read -rp "Enter GitHub proxy URL (e.g. https://your-proxy/https://, press Enter to skip): " proxy_url
        if [ -n "${proxy_url}" ]; then
            mkdir -p "$(dirname "${GITHUB_PROXY_CONFIG_FILE}")"
            echo "${proxy_url}" > "${GITHUB_PROXY_CONFIG_FILE}"
            export GITHUB_PROXY="${proxy_url}"
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
        local url="https://codeload.github.com/QuietSugar/ubuntu-server-init/zip/refs/heads/dev"
        if [ -n "${GITHUB_PROXY}" ]; then
            url="${GITHUB_PROXY}${url}"
        fi
        echo "${url}"
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
    load_or_ask_github_proxy
    download_and_un_tar
    cd "${UBUNTU_SERVER_INIT_DIR}"
    bash main.sh
  fi
}

main


