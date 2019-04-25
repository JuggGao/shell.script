#!/bin/bash
# -----------------------------
# CentOS 7 系统通用配置
# 
# 作者：Peng.Gao
# 邮箱：jugg.gao@qq.com
# 时间：2019年4月13日
# -----------------------------

function config_iptables {

    firewalld_status=$(systemctl status firewalld | awk 'NR==3 { print $1,$2,$3}')

    echo -e "1. 关闭防火墙"
    echo -e "\t\c"
    read -p "是否关闭防火墙（y/n）：" input
    if [[ ${input} == "y" ]] || [[ ${input} == "Y" ]] || [[ ${input} == "" ]]; then
        systemctl disable --now firewalld.service > /dev/null 2>&1 || break
        echo -e "\t关闭防火墙\t[\033[32m ok \033[0m]"
    fi

    echo -e "\t当前防火墙状态为：\033[33m ${firewalld_status} \033[0m"
}


function config_selinux {

    selinux_status=$(getenforce)

    echo -e "2. 关闭 SELinux"
    echo -e "\t\c"
    read -p "是否关闭 SELinux（y/n）：" input
    if [[ ${input} == "y" ]] || [[ ${input} == "Y" ]] || [[ ${input} == "" ]]; then
        setenforce 0 && sed -ri '/^[^#]*SELINUX=/s#=.+$#=disabled#' /etc/selinux/config || exit 1
        echo -e "\t关闭 SELinux\t[\033[32m ok \033[0m]"
    fi

    echo -e "\t当前 SELinux 状态为：\033[33m ${selinux_status} \033[0m"

}


function config_limits {

    echo -e "3. Limits 配置"
    echo -e "\t\c"
    read -p "是否配置 Limits（y/n）" input
    if [[ ${input} == "y" ]] || [[ ${input} == "Y" ]] || [[ ${input} == "" ]]; then

        grep "LIMITS ENV" /etc/security/limits.conf > /dev/null
        if [[ $? -eq 0 ]]; then
            echo -e "\tLimits 配置已经初始化\t[\033[32m ok \033[0m]"
        else
            echo -e "# LIMITS ENV" >> /etc/security/limits.conf
            echo -e "*\tsoft\tnofile\t655350" >> /etc/security/limits.conf
            echo -e "*\thard\tnofile\t655350" >> /etc/security/limits.conf
            echo -e "*\tsoft\tnproc\t655350" >> /etc/security/limits.conf
            echo -e "*\thard\tnproc\t655350" >> /etc/security/limits.conf
            echo -e "*\tsoft\tnofile\t655350" >> /etc/security/limits.d/20-nproc.conf
            echo -e "*\thard\tnofile\t655350" >> /etc/security/limits.d/20-nproc.conf
            echo "ulimit -n 655350" >> /etc/profile
            source /etc/profile
            echo -e "\tLimits 配置已经初始化\t[\033[32m ok \033[0m]"
        fi

        echo -e "\tLimits 配置为："
        awk '/LIMITS ENV/,0 { printf "\t\033[33m %s \033[0m\n", $0 }' /etc/security/limits.conf

    else
        echo -e "\tLimits 配置为系统默认值：\033[33m 1024 \033[0m"
    fi
}


function config_sysctl {

    echo -e "4. 优化系统内核参数"
    echo -e "\t\c"
    read -p "是否优化系统内核参数（y/n）" input
    if [[ ${input} == "y" ]] || [[ ${input} == "Y" ]] || [[ ${input} == "" ]]; then
        
        grep "SYSCTL ENV" /etc/sysctl.conf > /dev/null
        if [[ $? -eq 0 ]]; then
            echo -e "\tSysctl 已经优化完毕\t[\033[32m ok \033[0m]"
        else
            echo -e "# SYSCTL ENV" >> /etc/sysctl.conf
            echo "fs.file-max = 655536" >> /etc/sysctl.conf
            echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
            echo "net.core.somaxconn = 10240" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf
            echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
            echo "net.core.netdev_max_backlog = 32768" >> /etc/sysctl.conf
            echo "net.core.rmem_default = 8388608" >> /etc/sysctl.conf
            echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
            echo "net.core.somaxconn = 32768" >> /etc/sysctl.conf
            echo "net.core.wmem_default = 8388608" >> /etc/sysctl.conf
            echo "net.core.wmem_max = 16777216" >> /etc/sysctl.conf
            echo "net.ipv4.ip_local_port_range = 5000    65000" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_keepalive_time = 300" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_max_orphans = 3276800" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_max_syn_backlog = 65536" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_max_tw_buckets = 5000" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_mem = 94500000 915000000 927000000" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_syn_retries = 2" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_synack_retries = 2" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_timestamps = 0" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
            sysctl -p > /dev/null
        fi
    fi

    echo -e "\t当前已经优化的系统内核参数："
    awk '/SYSCTL ENV/,0 { printf "\t\033[33m %s \033[0m\n", $0 }' /etc/sysctl.conf
}


function create_lvm {

    echo -e "5. 创建 LVM 数据盘"
    echo -e "\t\c"
    read -p "是否创建 LVM 数据盘（y/n）" input
    if [[ ${input} == "y" ]] || [[ ${input} == "Y" ]] || [[ ${input} == "" ]]; then
        
        echo -e "\t1）创建磁盘分区"
        echo -e "\t\t\c"
        read -p "输入磁盘设备（默认 /dev/sdb）：" disk
        parted -s ${disk:-/dev/sdb} mklabel msdos mkpart primary 1 100% set 1 lvm on || break
        echo -e "\t\t磁盘分区创建完成\t[\033[32m ok \033[0m]"

        echo -e "\t2) 创建 VG 卷组"
        echo -e "\t\t\c"
        read -p "输入卷组名称（默认 data）：" vg
        vgcreate -q ${vg:-data} ${disk:-/dev/sdb}1 > /dev/null || break
        echo -e "\t\tVG 卷组创建完成\t[\033[32m ok \033[0m]"

        echo -e "\t3) 创建 LVM 卷"
        echo -e "\t\t\c"
        read -p "输入 LVM 卷名称（默认 data）：" lv
        echo -e "\t\t\c"
        read -p "输入 LVM 卷使用百分比（单位 %，默认 100）:" lv_percent
        lvcreate -q -l ${lv_percent:-100}%VG -n ${lv:-data} ${vg:-data} > /dev/null || break
        echo -e "\t\tLVM 卷创建完成\t[\033[32m ok \033[0m]"

        echo -e "\t4) 格式化文件系统"
        echo -e "\t\t\c"
        read -p "输入文件系统类型（默认 xfs）：" fs
        mkfs.${fs:-xfs} -q /dev/${vg:-data}/${lv:-data}
        echo -e "\t\t文件系统格式化完成\t[\033[32m ok \033[0m]"

        echo -e "\t5）挂载 LVM 卷"
        echo -e "\t\t\c"
        read -p "输入要挂载的目录（默认 /data）：" dir
        ls ${dir:-/data} > /dev/null 2>&1 || mkdir -p ${dir:-/data}
        grep -E "\s${dir:-/data}\s" /etc/fstab || echo -e "/dev/mapper/${vg:-data}-${lv:-data} ${dir:-/data}\t${fs:-xfs}\tdefaults\t0 0" >> /etc/fstab
        mount -a
        echo -e "\t\t目录已挂载\t[\033[32m ok \033[0m]"
    fi

    echo -e "\t当前磁盘挂载状态为："
    lsblk | awk '{ printf "\t\033[33m %s \033[0m\n", $0 }'
}

function extend_lvm {

    echo -e "6. 扩展 LVM 数据卷"
    echo -e "\t\c"
    read -p "是否扩展 LVM 数据卷（y/n）" input
    if [[ ${input} == "y" ]] || [[ ${input} == "Y" ]] || [[ ${input} == "" ]]; then

        echo -e "\t1）是否有新的磁盘设备（y/n）" has_new_disk
        if [[ ${has_new_disk} == "y" ]] || [[ ${has_new_disk} == "Y" ]] || [[ ${has_new_disk} == "" ]]; then

            echo -e "\t\t\c"
            read -p "输入磁盘设备（默认: /dev/sdb）" new_disk
            parted -s ${new_disk:-/dev/sdb} mklabel msdos mkpart primary 1 100% set 1 lvm on || break
            echo -e "\t\t磁盘分区创建完成\t[\033[32m ok \033[0m]"
        fi

        echo -e "\t2）扩展 LVM 卷"
        echo -e "\t\t\c"
        read -p "需要扩展的目录为（默认 /）：" dir
        if [[ ${has_new_disk} == "y" ]] || [[ ${has_new_disk} == "Y" ]] || [[ ${has_new_disk} == "" ]]; then

            lv=$(df / | awk 'NR!=1 { print $1 }')
            vg=$(lvdisplay ${lv} | awk '/VG Name/{ print $3}')

            vgextend -qf ${vg} ${new_disk:-/dev/sdb}1 > /dev/null || break
        fi

        echo -e "\t\t当前的 VG 卷组剩余空间为：\c" 
        vgs centos | awk ' NR!=1 { printf "\033[33m %s \033[0m\n", $NF}'
        echo -e "\t\t\c"
        read -p "输入要扩展的剩余量百分比（单位 %，默认 100）:" free_percent
        lvextend  -r -l  +${free_percent:-100}%FREE ${lv} > /dev/null
        echo -e "\t\tLVM 卷扩展完成\t[\033[32m ok \033[0m]"
    fi

    echo -e "\t当前磁盘挂载状态为："
    lsblk | awk '{ printf "\t\033[33m %s \033[0m\n", $0 }'

}


os=$(awk '{ print $1 }' /etc/centos-release)

if [[ ${os} == "CentOS" ]]; then

    while true; do

        echo -e "\n通用配置列表："

        echo -e "+-------------------------+------------------------------------+"
        echo -e "| 功能　　　              | 说明   　        　　              |"
        echo -e "+-------------------------+------------------------------------+"
        echo -e "| 1. 关闭防火墙           | 关闭网络流量控制　　　             |"
        echo -e "+-------------------------+------------------------------------+"
        echo -e "| 2. 关闭 SELinux　　　   | 关闭内核访问控制　　　             |"
        echo -e "+-------------------------+------------------------------------+"
        echo -e "| 3. 配置 Limits　　　    | 修改文件描述符硬限制与软限制    　 |"
        echo -e "+-------------------------+------------------------------------+"
        echo -e "| 4. 优化系统内核参数     | 优化打开文件描述符数量以及网络参数 |"
        echo -e "+-------------------------+------------------------------------+"
        echo -e "| 5. 创建 LVM 数据盘      | 创建 LVM 卷，格式化并挂载到数据目录|"
        echo -e "+-------------------------+------------------------------------+"
        echo -e "| 6. 扩展 LVM 卷          | 数据卷扩容                         |"
        echo -e "+-------------------------+------------------------------------+"

        echo -e "\n输入数字选择配置的功能（ 输入 a 选择所有，输入 q 退出）：\c"
        read num
        case ${num} in
            1 ) 
                config_iptables
                ;;
            2 ) 
                config_selinux
                ;;
            3 ) 
                config_limits
                ;;
            4 )
                config_sysctl
                ;;
            5 ) 
                create_lvm
                ;;
            6 )
                extend_lvm
                ;;
            a ) 
                config_iptables
                config_selinux
                config_limits
                config_sysctl
                create_lvm
                extend_lvm
                ;;
            q ) 
                exit 0
                ;;
            * )
                echo -e "找不到要配置的功能，请重新输入"
                ;;
        esac
    done

else
    echo -e "[ 系统不符合要求，请检查系统 ]"
fi