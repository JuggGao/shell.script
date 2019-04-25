#!/usr/bin/env bash
# ---------------------
# Description: Configure Docker Network Proxy
# Author: Peng.Gao
# Date: 2019-1-10
# Comment: Use the "source" to execute the script instead of sh. 
# --------------------

function configure_docker {
    [[ -d /etc/systemd/system/docker.service.d ]] || mkdir /etc/systemd/system/docker.service.d
    cat << EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="ALL_PROXY=socks5://127.0.0.1:1080/"
Environment="NO_PROXY=localhost,127.0.0.0/8,fz5yth0r.mirror.aliyuncs.com"
EOF
    
    systemctl daemon-reload && systemctl restart docker
    systemctl show --property=Environment docker
}

configure_docker