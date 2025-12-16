#!/bin/bash

function setup_proxy() {
    mkdir -p ~/.zsh/source
    local proxy_file="${HOME}/.ubunt-server-init/source/proxy.sh"
    if [ -s "${proxy_file}" ]; then
      source ${proxy_file}
    fi
    # 检查是否已设置代理
    local current_http_proxy=$(echo $http_proxy | head -n1)
    local current_https_proxy=$(echo $https_proxy | head -n1)

    if [ -n "$current_http_proxy" ] || [ -n "$current_https_proxy" ]; then
        printf "${YELLOW}检测到当前已设置代理:${CLEAR}\n"
        [ -n "$current_http_proxy" ] && echo "  HTTP_PROXY: $current_http_proxy"
        [ -n "$current_https_proxy" ] && echo "  HTTPS_PROXY: $current_https_proxy"

        printf "是否直接使用当前代理? [Y/n]: "
        read -r use_current < /dev/tty

        case $use_current in
            ''|y|Y|yes|YES)
                echo "将继续使用当前代理设置"
                return 0
                ;;
        esac
    fi

    printf "是否设置 HTTP/HTTPS 代理? [y/N]: "
    read -r set_proxy < /dev/tty

    case $set_proxy in
        y|Y|yes|YES)
            printf "请输入代理地址 (格式: http://proxy.host:port): "
            read -r proxy_url < /dev/tty

            if [ -n "$proxy_url" ]; then
                # 检测输入的字符串必须以http开头
                if [[ ! "$proxy_url" =~ ^https?:// ]]; then
                    echo "代理地址格式错误，必须以http://或https://开头"
                    return 1
                fi
                export http_proxy="$proxy_url"
                export https_proxy="$proxy_url"

                grep -q "export http_proxy=" ${proxy_file} 2>/dev/null && \
                    sed -i "s|export http_proxy=.*|export http_proxy=\"$proxy_url\"|" ${proxy_file} || \
                    echo "export http_proxy=\"$proxy_url\"" >> ${proxy_file}

                grep -q "export https_proxy=" ${proxy_file} 2>/dev/null && \
                    sed -i "s|export https_proxy=.*|export https_proxy=\"$proxy_url\"|" ${proxy_file} || \
                    echo "export https_proxy=\"$proxy_url\"" >> ${proxy_file}
                source ${proxy_file}
                echo "代理已设置为: $proxy_url"
            else
                echo "未输入代理地址，跳过代理设置"
            fi
            ;;
        *)
            echo "跳过代理设置"
            ;;
    esac

}


function unset_proxy() {
  unset http_proxy
  unset https_proxy
  unset all_proxy
  echo "Unset proxy"
}
                                                                                                                                                            # Shadowsocks proxy
alias proxy="set_proxy"
alias unproxy="unset_proxy"
