#!/usr/bin/env bash
# --------------------
# 说明：安装配置 Shadowscoks
# 作者：Peng.Gao
# 时间：2019-1-10
# --------------------

server_host="hk1-sta41.f92i4.space"
server_port=11472
local_address="127.0.0.1"
local_port=1080
password="TxqLrH6k4gBPygC"
method="chacha20-ietf-poly1305"

function install_shadows {
    easy_install --version || yum install -y python-setuptools
    pip --version || easy_install pip
    sslocal --version || pip install git+https://github.com/shadowsocks/shadowsocks.git@master
    rpm -qa | grep libsodium || yum install -y libsodium
}

function configure_shadows {
    [[ -d /etc/shadowsocks ]] || mkdir /etc/shadowsocks
    cat << EOF > /etc/shadowsocks/shadowsocks.json
{
    "server":"${server_host}",
    "server_port":${server_port},
    "local_address":"${local_address}",
    "local_port":${local_port},
    "password":"${password}",
    "timeout":300,
    "method":"${method}",
    "fast_open": false
}
EOF

    cat << EOF > /etc/systemd/system/shadowsocks.service
[Unit]
Description=Shadowsocks
[Service]
TimeoutStartSec=0
ExecStart=/usr/bin/sslocal -c /etc/shadowsocks/shadowsocks.json
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl status shadowsocks || systemctl enable --now shadowsocks && systemctl status shadowsocks
}

install_shadows
configure_shadows