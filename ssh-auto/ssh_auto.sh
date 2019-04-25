#!/usr/bin/env bash

# FileName: ssh_auto.sh
# Date: 2018-11-16 10:53:24
# Author: peng.gao
# Description: This script can achieve ssh password-free login.

os=$(awk '{ print $1 }' /etc/centos-release)

function execpt_install {
    echo -e "[ 开始检测并安装相关依赖包 ]"

    rpm -qa | grep -E "^expect-[0-9].*" > /dev/null
    if [[ $? != 0 ]]; then
        echo -e "\t[ 开始安装 execpt ]"
        yum install -y expect > /dev/null
        echo -e "\t[ expect 安装完毕 ]"
    else
        echo -e "\t[ execpt 已经安装 ]"
    fi

    rpm -qa | grep -E "^expect-devel-[0-9].*" > /dev/null
    if [[ $? != 0 ]]; then
        echo -e "\t[ 开始安装 execpt-devel ]"
        yum install -y expect-devel > /dev/null
        echo -e "\t[ expect-devel 安装完成 ]"
    else
        echo -e "\t[ execpt-devel 已经安装 ]"
    fi

    rpm -qa | grep -E "^tcl-[0-9].*" > /dev/null
    if [[ $? != 0 ]]; then
        echo -e "\t[ 开始安装 tcl ]"
        yum install -y tcl > /dev/null
        echo -e "\t[ tcl 安装完成 ]"
    else
        echo -e "\t[ tcl 已经安装 ]"
    fi

}

function ssh_keygen {
    echo -e "[ 开始检测并生成秘钥对 ]"
    if [[ ! -f "$HOME/.ssh/authorized_keys" ]]; then
        ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
        echo -e "\t[ 密钥对已经生成完毕 ]"
    else
        echo -e "\t[ 密钥对已经存在 ]"
    fi
}

function ssh_keygen_copy {
    echo -e "[ 开始拷贝公钥至目标主机 ]"
    while read line; do
        ip=$(echo $line | awk '{ print $1 }')
        user=$(echo $line | awk '{ print $2 }')
        passwd=$(echo $line | awk '{ print $3 }')

expect <<EOF > /dev/null
        spawn ssh-copy-id -i $HOME/.ssh/id_rsa.pub ${user}@${ip}
        expect {
            "yes/no" { send "yes\n";exp_continue}
            "password" { send "${passwd}\n"}
         }
EOF
    done < host_ip
    echo -e "\t[ 公钥文件拷贝完成 ]"
}

if [[ ${os} == "CentOS" ]]; then
    execpt_install
    ssh_keygen
    ssh_keygen_copy
else
    echo -e "[ 系统不符合要求，请检查系统 ]"
fi