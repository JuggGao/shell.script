#!/usr/bin/env bash

mysql_port="3306"
mysql_host="10.10.113.15"
mysql_user="root"
mysql_passwd='Pa55w0rd!s'
mysql_db=("ambow_group" "cooperation" "edurp" "iqc_iot" "qiaomeng" "radius" "runningChina" "tickets" "vbplus")
mysql_back_dir="/tmp/mysql_backup"
date=$(date +%F)

function env_check {
    clinet_install=$(rpm -qa | grep -E "^mysql-.*-client-.*")
    if [[ $? != 0 ]]; then
        echo -e "[ Error ] MySQL 客户端程序未发现,请下载 mysql-client 程序"
        exit 1
    fi

    if [[ ! -d ${mysql_back_dir} ]]; then
        mkdir -p ${mysql_back_dir}
    fi
}

function mysql_dump {
    mkdir ${mysql_back_dir}/${date}
    for db in ${mysql_db[@]}; do
        mysqldump -h${mysql_host} -P${mysql_port} -u${mysql_user} -p${mysql_passwd}  ${db} > ${mysql_back_dir}/${date}/${db}.sql
        if  [[ $? != 0 ]]; then
            echo -e "[$date] ${db} 备份失败" >> ${mysql_back_dir}/dump.log
        else
            echo -e "[$date] ${db} 备份成功" >> ${mysql_back_dir}/dump.log
        fi
    done
}

function mysql_clean {

find ${mysql_back_dir}  -type d -mtime +7  -exec rm -rf {} \;

}

env_check
mysql_dump
mysql_clean