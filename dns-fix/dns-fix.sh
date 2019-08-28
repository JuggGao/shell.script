#!/bin/bash
#
# Author: Alibaba
# Version: 1.0
# Date: 2017/09/09
# Description : After centos6/rhel6,The resolver uses the same socket for the A and AAAA requests.Some hardware mistakenly only sendsback  one reply. When that happens the client system will sit and wait for the second reply.  Turn-ing option single-request-reopen on changes this behavior so that if two requests from the same port are not handledcorrectly it will close the  socket and open a new one before sending the second request. 

function get_debian()
{
    for i in 'issue' 'issue.net' 'os-release'; do
         if grep -i -q 'Debian' /etc/$i >& /dev/null ; then
             resolv_conf="/etc/resolvconf/resolv.conf.d/tail"
             vm_issue='debian'
             return
         fi
    done
}

function get_ubuntu()
{
    grep -i "Ubuntu" /etc/issue >& /dev/null
    if [[ $? == 0 ]];then
        resolv_conf="/etc/resolvconf/resolv.conf.d/tail"
        vm_issue="ubuntu"
    fi
}

function get_centos()
{
    for i in issue issue.net centos-release redhat-release ; do
        [[ ! -f /etc/$i ]] && continue
         grep -i -q 'CentOS' /etc/$i
         if [[ $? -eq 0 ]]; then
             resolv_conf="/etc/resolv.conf"
             vm_issue='centos'
             return
         fi
    done
}


function fix_dns()
{

    if [  -f $resolv_conf ]; then
        dns_options=`cat $resolv_conf | grep "\<options\>" 2>/dev/null`
        if [ "$dns_options" == "" ]; then
            echo "options timeout:2 attempts:3 rotate single-request-reopen" >>$resolv_conf
        else
            single=`cat $resolv_conf | grep "\<single-request-reopen\>" 2>/dev/null`
            if [ "$single" == "" ]; then
                sed -i "s/^options.*/& single-request-reopen/" $resolv_conf
            else
                echo "single-request-reopen config has already exists"
                return
            fi
        fi
        if [[  "$vm_issue" == "debian" || "$vm_issue" == "ubuntu" ]] ;then
            resolvconf -u
        fi

        if [ $? -eq 0 ];then
            echo "success:0"
        fi

    else
        echo "Failed:can not find resolv.conf file"
    fi
}


function get_issue()
{
    vm_issue=""
    resolv_conf=""

func_list=(
get_debian
get_ubuntu
get_centos
)
    for f in ${func_list[@]}; do
        $f
        [[ -n $vm_issue ]] && return
    done
}

function check_issue()
{
    if [[ $vm_issue == "" || $resolv_conf == "" ]];then
        echo "failed: script only support centos, debian, ubuntu"
        exit 1
    fi
}

get_issue
check_issue
fix_dns
