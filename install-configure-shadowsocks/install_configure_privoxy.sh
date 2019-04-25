#!/usr/bin/env bash
# ---------------------
# Description: Install and Configure of Privoxy
# Author: Peng.Gao
# Date: 2019-1-10
# Comment: Use the "source" to execute the script instead of sh. 
# --------------------

proxy_socket="127.0.0.1:1080"
proxy_host="127.0.0.1"

function install_privoxy {
    privoxy --version || yum install -y privoxy
}

function configure_privoxy {
    grep -E "^listen-address.+:8118" /etc/privoxy/config || exit 1
    grep -E "^forward-socks5t" /etc/privoxy/config || sed -i '/^#.*forward-socks5t.*127.0.0.1:9050.*/a\forward-socks5t / ${proxy_socket} .' /etc/privoxy/config

    systemctl status privoxy || systemctl enable --now privoxy && systemctl status privoxy
}

function import_env {
    cat << EOF >> ~/.bash_profile

# Proxy Settings
PROXY_HOST=${proxy_host}
export all_proxy=http://$PROXY_HOST:8118
export ftp_proxy=http://$PROXY_HOST:8118
export http_proxy=http://$PROXY_HOST:8118
export https_proxy=http://$PROXY_HOST:8118
EOF
    source ~/.bash_profile
}

install_privoxy
configure_privoxy
import_env