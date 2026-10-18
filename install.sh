#!/bin/sh
# ubuntu-server-init 引导脚本：下载 release 里的 usinit 二进制并安装。
#
#   curl -fsSL https://raw.githubusercontent.com/QuietSugar/ubuntu-server-init/master/install.sh | sh
#
# 环境变量：
#   USINIT_INSTALL_DIR  安装目录（默认 ~/.local/bin）
#   USINIT_VERSION      指定 tag（默认 latest，如 v0.0.5）
#   GH_PROXY            GitHub 加速前缀（如 https://gh-proxy.com/）；留空则直连失败后自动回退
#   USINIT_NO_MIRROR=1  关闭自动回退（只直连）
#   https_proxy/http_proxy  标准代理，curl 自动生效
set -eu

REPO="QuietSugar/ubuntu-server-init"
INSTALL_DIR="${USINIT_INSTALL_DIR:-$HOME/.local/bin}"
DEFAULT_MIRRORS="https://gh-proxy.com/ https://ghfast.top/"

os="$(uname -s)"
if [ "$os" != "Linux" ]; then
    echo "error: 只支持 Linux（当前: $os）" >&2
    exit 1
fi
arch="$(uname -m)"
case "$arch" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) echo "error: 不支持的架构: $arch（仅 amd64 / arm64）" >&2; exit 1 ;;
esac

if [ "${USINIT_VERSION:-latest}" = "latest" ]; then
    base="https://github.com/$REPO/releases/latest/download"
else
    base="https://github.com/$REPO/releases/download/${USINIT_VERSION}"
fi
asset="usinit_linux_$arch"

mirrors=""
if [ -n "${GH_PROXY:-}" ]; then
    mirrors="${GH_PROXY%/}/"
elif [ "${USINIT_NO_MIRROR:-0}" != "1" ]; then
    mirrors="$DEFAULT_MIRRORS"
fi

fetch() {
    curl -fsSL --connect-timeout 10 --max-time 120 --retry 2 -o "$2" "$1"
}

download() {
    _path="$1"
    _dest="$2"
    if fetch "$base/$_path" "$_dest"; then
        return 0
    fi
    for m in $mirrors; do
        echo "  直连失败，改用加速站: $m" >&2
        if fetch "${m}$base/$_path" "$_dest"; then
            return 0
        fi
    done
    return 1
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "下载 $asset ..."
if ! download "$asset" "$tmp/$asset"; then
    echo "error: 下载失败；可设 GH_PROXY 或 https_proxy 后重试" >&2
    exit 1
fi
if ! download "checksums.txt" "$tmp/checksums.txt"; then
    echo "error: 下载 checksums.txt 失败" >&2
    exit 1
fi

expected="$(grep " $asset$" "$tmp/checksums.txt" || true)"
if [ -z "$expected" ]; then
    echo "error: checksums.txt 里没有 $asset" >&2
    exit 1
fi
if command -v sha256sum >/dev/null 2>&1; then
    printf '%s\n' "$expected" | (cd "$tmp" && sha256sum -c -) >/dev/null
else
    printf '%s\n' "$expected" | (cd "$tmp" && shasum -a 256 -c -) >/dev/null
fi
echo "sha256 校验通过"

mkdir -p "$INSTALL_DIR"
install -m 0755 "$tmp/$asset" "$INSTALL_DIR/usinit"
echo "已安装: $INSTALL_DIR/usinit"
case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
        echo ""
        echo "提示: $INSTALL_DIR 不在 PATH，把它加进 shell rc 的 PATH 即可"
        ;;
esac
"$INSTALL_DIR/usinit" version
