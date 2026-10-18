#!/bin/bash

ROOT_DIR=$(pwd)
SH=/bin/bash

# 用 $'...' 让变量里是真正的 ESC：否则 printf 走 %s 参数时不会转义 \033
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
GRAY=$'\033[0;37m'
CLEAR=$'\033[0m'


function print_logo() {
    echo "🍰🍪🧁🍬🍨 ubuntu-server-init 🥧🎂🍦🍭🍩";
}

function l_skip() {
    printf '%s[SKIP] %s%s\n' "${GRAY}" "$*" "${CLEAR}"
}

function l_info() {
    echo "[INFO]" "$@"
}

function l_error() {
    printf "${RED}[ERRO] %s${CLEAR}\n" "$@"
}

function l_success() {
    printf "${GREEN}[SUCC] %s${CLEAR}\n" "$@"
}

function l_warn() {
    printf "${YELLOW}[WARN] %s${CLEAR}\n" "$@"
}

# TUI 进度标记：USINIT_PROGRESS=1 时输出结构化行；默认关闭，输出与之前逐字节一致
function progress() {
    if [ "${USINIT_PROGRESS:-0}" = "1" ]; then
        echo "@@USINIT@@ step $1/$2 $3 $4@@"
    fi
}

function run_scripts_in_dir() {
    DIR="$1"
    FILES=$(find "$ROOT_DIR/$DIR" -name '*.sh' | sort)
    TOTAL=$(echo "$FILES" | wc -l | tr -d ' ')
    INDEX=1
    for FILE in $FILES; do
        BASE=$(basename "$FILE")
        case " ${SKIP_STEPS:-} " in
            *" $BASE "*)
                l_skip "[${INDEX}/${TOTAL}] skip $BASE (SKIP_STEPS)"
                progress "${INDEX}" "${TOTAL}" "$BASE" skip
                INDEX=$((INDEX + 1))
                continue
                ;;
        esac
        l_warn "[${INDEX}/${TOTAL}] run $BASE"
        progress "${INDEX}" "${TOTAL}" "$BASE" start
        if ! "$SH" "$FILE"; then
            l_error "[${INDEX}/${TOTAL}] $BASE failed"
            progress "${INDEX}" "${TOTAL}" "$BASE" fail
            exit 1
        fi
        progress "${INDEX}" "${TOTAL}" "$BASE" ok
        INDEX=$((INDEX + 1))
    done
}

function install_via_apt() {
    PACKAGE="$1"

    if ! dpkg-query -W -f='${Status}' "$PACKAGE" 2>/dev/null | grep -q "install ok installed"; then
        l_warn "installing $PACKAGE"
        if ! sudo -E apt install -y "$PACKAGE"; then
            l_error "failed to install package ${PACKAGE}"
            return 1
        fi
        l_success "package ${PACKAGE} installed."
    else
        l_skip "package $PACKAGE already installed."
    fi
}

function install_remote_deb() {
    URL="$1"
    PACKAGE="${2:-}"

    if [ -n "$PACKAGE" ]; then
        if sudo dpkg -s "$PACKAGE" &> /dev/null; then
            l_skip "package $PACKAGE already installed."
            return 0
        fi
    fi

    l_warn "installing $PACKAGE"

    FILE_NAME=$(basename "$URL")
    if ! fetch "${FILE_NAME}" "${URL}"; then
        l_error "failed to download ${PACKAGE} from ${URL}"
        return 1
    fi

    if ! sudo dpkg -i "./${FILE_NAME}"; then
        l_error "failed to install ${PACKAGE}"
        rm -f "./${FILE_NAME}"
        return 1
    fi

    rm -f "./${FILE_NAME}"

    l_success "deb package ${PACKAGE} installed."
}

function install_via_flatpak() {
    PACKAGE="$1"
    HUB="flathub"

    if ! flatpak info "$PACKAGE" &> /dev/null; then
        l_warn "installing $PACKAGE"
        flatpak install -y "${HUB}"  "${PACKAGE}"
        l_success "package ${PACKAGE} installed."
    else
        l_skip "${PACKAGE} already installed."
    fi
}

# 安装 go 包。默认已存在则跳过；第二个参数传 update 时总是安装/更新。
# 注意：@latest 由 GOPROXY 解析，代理与本地 module cache 都可能让频繁调试时
# 拿不到刚发布/刚推送的版本；需要确定性时请在调用处指定明确版本（见 hall-kit.sh）。
function install_via_go() {
    PACKAGE="$1"
    MODE="${2:-skip}"

    REPO=$(echo "${PACKAGE}" | cut -d @ -f 1)
    if [ -z "${REPO}" ]; then
        l_error "go package ${PACKAGE} error"
        return 1
    fi

    if ! command -v go &> /dev/null; then
        l_error "command go not found."
        return 1
    fi

    BIN_PATH="$(go env GOBIN)"
    if [ -z "${BIN_PATH}" ]; then
        BIN_PATH="$(go env GOPATH)/bin"
    fi
    CMD=$(basename "${REPO}")

    if [ "${MODE}" != "update" ] && [ -f "${BIN_PATH}/${CMD}" ]; then
        l_skip "go package ${PACKAGE} already installed."
        return 0
    fi

    l_warn "installing/updating go package ${PACKAGE}"
    if ! go install "${PACKAGE}"; then
        l_error "failed to install ${PACKAGE}"
        return 1
    fi
    l_success "go package ${PACKAGE} installed/updated."
}

function install_prebuilt_bin() {
    CMD="$1"
    URL="$2"
    BIN_DIR=/usr/bin

    if [ -f "${BIN_DIR}/${CMD}" ]; then
        l_skip "${CMD} already installed."
    else
        l_warn "installing ${CMD}"
        fetch "${CMD}" "${URL}"
        chmod a+x "${CMD}"
        sudo mv "${CMD}" "${BIN_DIR}/${CMD}"
        l_success "${CMD} installed."
    fi
}

function install_prebuilt_zipbin() {
    CMD="$1"
    URL="$2"
    BIN_DIR=/usr/bin

    if [ -f "${BIN_DIR}/${CMD}" ]; then
        l_skip "${CMD} already installed."
    else
        l_warn "installing ${CMD}"
        fetch "${CMD}.zip" "${URL}"
        unzip "${CMD}.zip"
        chmod a+x "${CMD}"
        sudo mv "${CMD}" "${BIN_DIR}/${CMD}"
        rm "${CMD}.zip"
        l_success "${CMD} installed."
    fi
}

function install_via_pip() {
    PACKAGE="$1"

    if ! command -v pip &> /dev/null; then
        l_error "command pip not found."
        return 1
    fi

    if ! pip show "${PACKAGE}" &> /dev/null; then
        l_warn "installing python ${PACKAGE}"
        if ! pip install "${PACKAGE}"; then
            l_error "failed to install ${PACKAGE}"
            return 1
        fi
    else
        l_skip "${PACKAGE} already installed."
    fi
}

function set_go_env() {
    KEY="$1"
    VAL="$2"

    if ! command -v go &> /dev/null; then
        l_error "can't set go env caused by command go not found."
        return 1
    fi

    OLDVAL=$(go env "${KEY}")

    if [ -n "${OLDVAL}" ]; then
        if [[ ",${VAL}," = *",${OLDVAL},"* ]]; then
            l_skip "go env ${KEY}=${VAL} already configured."
            return
        fi
        VAL="${OLDVAL},${VAL}"
    fi

    go env -w "${KEY}=${VAL}"

    l_success "go env ${KEY}=${VAL}"
}

function ctrl_c() {
    l_error "user interrupt"
    exit 1
}

function get_distrib_codename() {
    if [ -f /etc/upstream-release/lsb-release ]; then
        . /etc/upstream-release/lsb-release
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
    fi
    if [ -z "${DISTRIB_CODENAME}" ]; then
        DISTRIB_CODENAME=$(lsb_release -cs)
    fi
    echo "${DISTRIB_CODENAME}"
}

function get_distrib_id() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "${ID}"
    else
        echo "ubuntu"
    fi
}

function get_extension() {
    FILENAME="$1"
    EXT="${FILENAME##*.}"
    if [ "${EXT}" == "gz" ]; then
        FILENAME="${FILENAME%.*}"
        EXT2="${FILENAME##*.}"
        EXT="${EXT2}.${EXT}"
    fi
    echo "${EXT}"
}



# ---- GitHub 加速：GH_PROXY（内置自动探测，可覆盖）----
# 默认先试直连，直连不通再依次试 GH_PROXY_AUTO_LIST 的加速站，结果缓存到环境变量。
#   GH_PROXY            显式指定加速前缀（如 https://gh-proxy.com/），设置后不再探测
#   GH_PROXY_AUTO=0     关闭自动探测（强制直连）
#   GH_PROXY_AUTO_LIST  候选加速站（空格分隔）
GH_PROXY_CANARY="${GH_PROXY_CANARY:-https://raw.githubusercontent.com/rupa/z/master/z.sh}"

detect_gh_proxy() {
    if [ -n "${_GH_PROXY_DONE:-}" ]; then
        printf '%s' "${_GH_PROXY_VAL:-}"
        return 0
    fi
    if [ -n "${GH_PROXY:-}" ]; then
        _GH_PROXY_VAL="${GH_PROXY%/}"
    elif [ "${GH_PROXY_AUTO:-1}" != "1" ] || ! command -v curl >/dev/null 2>&1; then
        _GH_PROXY_VAL=""
    elif curl -fsSL --connect-timeout 3 --max-time 6 -o /dev/null "${GH_PROXY_CANARY}" 2>/dev/null; then
        _GH_PROXY_VAL=""
    else
        _GH_PROXY_VAL=""
        local cand
        for cand in ${GH_PROXY_AUTO_LIST:-https://gh-proxy.com/ https://ghfast.top/}; do
            if curl -fsSL --connect-timeout 3 --max-time 8 -o /dev/null "${cand%/}/${GH_PROXY_CANARY}" 2>/dev/null; then
                _GH_PROXY_VAL="${cand%/}"
                break
            fi
        done
    fi
    export _GH_PROXY_DONE=1
    export _GH_PROXY_VAL
    printf '%s' "${_GH_PROXY_VAL}"
}

gh_url() {
    case "$1" in
        https://raw.githubusercontent.com/*|https://github.com/*|https://codeload.github.com/*)
            if [ -z "${_GH_PROXY_DONE:-}" ]; then detect_gh_proxy >/dev/null 2>&1; fi
            if [ -n "${_GH_PROXY_VAL:-}" ]; then printf '%s/%s\n' "${_GH_PROXY_VAL%/}" "$1"; else printf '%s\n' "$1"; fi
            ;;
        *)
            printf '%s\n' "$1"
            ;;
    esac
}

fetch() {
    detect_gh_proxy >/dev/null 2>&1
    if [ "$#" -eq 2 ]; then
        _fetch_dest="$1"
        _fetch_url="$(gh_url "$2")"
    else
        _fetch_dest=""
        _fetch_url="$(gh_url "$1")"
    fi
    if which curl > /dev/null; then
        if [ -n "$_fetch_dest" ]; then curl -fL --connect-timeout 10 --max-time 60 --retry 2 -o "$_fetch_dest" "$_fetch_url"; else curl -fsSL --connect-timeout 10 --max-time 60 --retry 2 "$_fetch_url"; fi
    elif which wget > /dev/null; then
        if [ -n "$_fetch_dest" ]; then wget --timeout=60 --tries=3 -O "$_fetch_dest" "$_fetch_url"; else wget -nv --timeout=60 --tries=3 -O - "$_fetch_url"; fi
    else
        echo "Can't find curl or wget, can't download package"
        exit 1
    fi
}
