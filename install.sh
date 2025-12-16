#!/bin/bash

set -e
# git 相关目录
THIS_GIT_USER_DIR="${HOME}/git-repo/github.com/QuietSugar"
UBUNTU_SERVER_INIT_GIT_DIR="${THIS_GIT_USER_DIR}/ubuntu-server-init"



fetch(){
    if which curl > /dev/null; then
        if [ "$#" -eq 2 ]; then curl -fL -o "$1" "$2"; else curl -fsSL "$1"; fi
    elif which wget > /dev/null; then
        if [ "$#" -eq 2 ]; then wget -O "$1" "$2"; else wget -nv -O - "$1"; fi
    else
        echo "Can't find curl or wget, can't download package"
        exit 1
    fi
}

get_latest_release_url(){
    if [ -n "${RELEASE_FILE_URL}" ]; then
        echo "${RELEASE_FILE_URL}"
    else
        echo "https://github.com/QuietSugar/ubunt-server-init/archive/refs/heads/master.zip"
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
  mkdir -p ${THIS_GIT_USER_DIR}/
  mv ubuntu-server-init* "${UBUNTU_SERVER_INIT_GIT_DIR}"
}

main(){
  if [ -d "${UBUNTU_SERVER_INIT_GIT_DIR}" ]; then
    echo "GIT DIR 已经存在"
  else
    download_and_un_tar
    cd "${UBUNTU_SERVER_INIT_GIT_DIR}"
    bash main.sh
  fi
}

main


