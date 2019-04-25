#!/bin/bash
# -----------------------------
# CentOS 7 服务单机安装
# 
# 作者：Peng.Gao
# 邮箱：jugg.gao@qq.com
# 时间：2019年4月15日
# -----------------------------

function install_java {

	echo -e "1. 安装 Java 服务"

	while true; do
		echo -e "\t\c"
		read -p "选择要安装的版本（jre 或 jdk，默认 jre）：" java_version
		echo -e "\t\c"
		read -p "选择要安装的目录（默认为 /usr/local/）": java_home

		ls ${java_verion:-/usr/local}/java/ > /dev/null 2>&1 || mkdir -p ${java_home:-/usr/local}/java/

		if [[ ${java_version} == "jre" ]] || [[ ${java_version} == "JRE" ]] || [[ ${java_version} == "" ]]; then

			java -version > /dev/null 2>&1 || \
				tar zxf ./packages/java/server-jre-8u202-linux-x64.tar.gz -C ${java_home:-/usr/local}/java/
			break

		elif [[ ${java_version} == "jdk" ]] || [[ ${java_version} == "JDK" ]]; then
			
			java -version > /dev/null 2>&1 || \
				tar zxf ./packages/java/jdk-8u202-linux-x64.tar.gz -C ${java_home:-/usr/local}/java/

			break

		else
			echo -e "版本输入错误，请重新输入版本号"
			continue
		fi
	done

	grep "Java ENV" /etc/profile > /dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		echo -e "\n# Java ENV" >> /etc/profile && \
		echo -e "export JAVA_HOME=${java_verion:-/usr/local}/java/jdk1.8.0_202" >> /etc/profile && \
		echo -e "export JRE_HOME=\${JAVA_HOME}/jre" >> /etc/profile && \
		echo -e "export CLASSPATH=.:\${JAVA_HOME}/lib:\${JRE_HOME}/lib" >> /etc/profile && \
		echo -e "export PATH=\${JAVA_HOME}/bin:\$PATH" >> /etc/profile
	fi
	source /etc/profile

	echo -e "\tJava 8 安装完成\t[\033[32m ok \033[0m]"

	ppid=$(ps -fp $$ | awk 'NR!=1 { print $3 }')
	if [[ ppid -ne 0 ]]; then
		echo -e "\t\033[95m 警告：使用 sh 执行脚本无法使当前终端环境变量生效，需使用 source 执行脚本或在当前终端执行 source /etc/profile 使 Java 环境变量生效\033[0m"
	fi
	echo -e "\t当前 Java 版本为：" 
	java -version |& awk '{ printf "\t\033[33m%s\033[0m\n", $0 }'

}

function install_tomcat {

	echo -e "2. 安装 Tomcat 服务"
	echo -e "\t\c"
	read -p "选择要安装的目录（默认为 /usr/local/）": tomcat_home

	source /etc/profile
	if [[ ! $JAVA_HOME ]]; then
		echo -e "\t\033[31m未检测到 Java 目录，请检测安装 Java 服务是否安装\033[0m"
		break
	fi

	groupadd -f -g 53 tomcat
	id tomcat &> /dev/null || useradd tomcat -u 53 -g 53 -M -d ${tomcat_home:-/usr/local}/tomcat/apache-tomcat-8.5.40 -c "Apache Tomcat" -s /sbin/nologin &> /dev/null

	ls ${java_verion:-/usr/local}/tomcat > /dev/null 2>&1 || mkdir -p ${tomcat_home:-/usr/local}/tomcat/
	tar zxf ./packages/tomcat/apache-tomcat-8.5.40.tar.gz -C ${tomcat_home:-/usr/local/}/tomcat/
	chown tomcat:tomcat ${tomcat_home:-/usr/local/}/tomcat/ -R

	grep -e "^JAVA_HOME" ${tomcat_home:-/usr/local}/tomcat/apache-tomcat-8.5.40/bin/catalina.sh || \
		sed -ri  "/# OS specific support/i\JAVA_HOME=$JAVA_HOME\n\
			CATALINA_PID=${tomcat_home:-/usr/local}/tomcat/apache-tomcat-8.5.40/temp/tomcat.pid" \
			${tomcat_home:-/usr/local}/tomcat/apache-tomcat-8.5.40/bin/catalina.sh
	grep -e "^JAVA_HOME" ${tomcat_home:-/usr/local}/tomcat/apache-tomcat-8.5.40/bin/setclasspath.sh || \
		sed -ri  "/# Make sure prerequisite/i\JAVA_HOME=$JAVA_HOME\n" ${tomcat_home:-/usr/local}/tomcat/apache-tomcat-8.5.40/bin/setclasspath.sh

	cat <<-EOF > /usr/lib/systemd/system/tomcat.service
	[Unit]  
	Description=Tomcat8
	After=syslog.target network.target remote-fs.target nss-lookup.target  

	[Service]
	Type=forking

	Environment=JAVA_HOME=$JAVA_HOME
	Environment=CATALINA_PID=${tomcat_home:-/usr/local}/tomcat/apache-tomcat-8.5.40/temp/tomcat.pid
	Environment=CATALINA_HOME=${tomcat_home:-/usr/local}/tomcat/apache-tomcat-8.5.40
	Environment=CATALINA_BASE=${tomcat_home:-/usr/local}/tomcat/apache-tomcat-8.5.40

	ExecStart=${tomcat_home:-/usr/local}/tomcat/apache-tomcat-8.5.40/bin/startup.sh
	ExecReload=/bin/kill -s HUP $MAINPID
	ExecStop=${tomcat_home:-/usr/local}/tomcat/apache-tomcat-8.5.40/bin/shutdown.sh

	PrivateTmp=true
	User=tomcat
	Group=tomcat

	[Install]
	WantedBy=multi-user.target
	EOF
	systemctl daemon-reload

	echo -e "\tTomcat 8 安装完成\t[\033[32m ok \033[0m]"
	echo -e "\t当前 Tomcat 版本为："
	${tomcat_home:-/usr/local}/tomcat/apache-tomcat-8.5.40/bin/version.sh |& awk '{ printf "\t\033[33m%s\033[0m\n", $0 }'

	echo -e "\n\t是否启动 Tomcat 服务并配置开机自启动（y/n）：\c"
	read is_tomcat_auto_start
	if [[ ${is_tomcat_auto_start} == "y" ]] || [[ ${is_tomcat_auto_start} == "Y" ]] || [[ ${is_tomcat_auto_start} == "" ]]; then
		systemctl enable --now tomcat |& awk '{ printf "\n\t\033[92m%s\033[0m\n", $0 }'
	fi

	echo -e "\n\t\033[95m注意，请使用 Systemd 管理 Tomcat 服务，不要使用 root 用户执行脚本启停 Tomcat 服务\033[0m"
	echo -e "\t\033[95m启停服务命令如下：\033[0m"
	echo -e "\t\033[93m启动 Tomcat 服务：systemctl start tomcat\033[0m"
	echo -e "\t\033[93m重启 Tomcat 服务：systemctl restart tomcat\033[0m"
	echo -e "\t\033[93m停止 Tomcat 服务：systemctl stop tomcat\033[0m"

}


function install_nginx {

	systec_cpus=$(lscpu | awk '/^CPU\(s\):/{ print $NF }')

	echo -e "3. 安装 Nginx 服务"
	nginx -v &> /dev/null || yum localinstall -y ./packages/nginx/* &> /dev/null
	echo -e "\tNginx 基础配置："
	echo -e "\t\c"
	read -p "指定 Nginx 工作进程用户（默认为 nginx）：" nginx_user
	echo -e "\t\c"
	read -p "指定 Nginx 工作进程数（默认为当前系统 CPU 核心数：${systec_cpus}）：" nginx_work_processes
	echo -e "\t\c"
	read -p "指定 Nginx 每个工作进程最大连接数（默认为 1024）：" nginx_work_connections

	sed -ri "/^user/s/user  .*;$/user  ${nginx_user:-nginx};/" /etc/nginx/nginx.conf
	sed -ri "/^worker_processes/s/worker_processes  .*;/worker_processes  ${nginx_work_processes:-${systec_cpus}};/" /etc/nginx/nginx.conf
	sed -ri "/^\s?+worker_connections/s/worker_connections  .*;/worker_connections  ${nginx_work_connections:-1024};/" /etc/nginx/nginx.conf

	echo -e "\tNginx 安装完成\t[\033[32m ok \033[0m]"
	echo -e "\t当前 Nginx 版本为："
	nginx -v |& awk '{ printf "\t\033[33m%s\033[0m\n", $0 }'
	echo -e "\t\033[33mNginx 配置文件目录：/etc/nginx/\033[0m" 
	echo -e "\t\033[33mNginx 日志文件目录：/var/log/nginx/\033[0m" 

	echo -e "\n\t是否启动 Nginx 服务并配置开机自启动（y/n）:\c"
	read is_nginx_auto_start
	if [[ ${is_nginx_auto_start} == "y" ]] || [[ ${is_nginx_auto_start} == "Y" ]] || [[ ${is_nginx_auto_start} == "" ]]; then
		systemctl enable --now nginx |& awk '{ printf "\n\t\033[92m%s\033[0m\n", $0 }'
	fi

	echo -e "\n\t\033[95m注意，请使用 Systemd 管理 Nginx 服务，不要使用 root 用户执行 nginx 二进制文件启停 Nginx 服务\033[0m"
	echo -e "\t\033[95m启停服务命令如下：\033[0m"
	echo -e "\t\033[93m启动 Nginx 服务：systemctl start nginx\033[0m"
	echo -e "\t\033[93m重启 Nginx 服务：systemctl restart nginx\033[0m"
	echo -e "\t\033[93m停止 Nginx 服务：systemctl stop nginx\033[0m"

}

function install_mysql {

	echo -e "4. 安装 MySQL 数据库"
	mysql --version &> /dev/null || rpm -qa | grep mariadb | xargs rpm -e --nodeps &&
	mysql --version &> /dev/null || yum localinstall -y ./packages/mysql/* &> /dev/null

	echo -e "\t1）MySQL 基础配置："
	echo -e "\t\t\c"
	read -p "指定 MySQL 数据文件目录（默认为 /var/lib/mysql）:" mysql_data_dir
	echo -e "\t\t\c"
	read -p "指定 MySQL 数据库默认字符集（默认为 utf8）：" mysql_character
	echo -e "\t\t\c"
	read -p "指定 MySQL 数据库最大连接数（默认为 500）：" mysql_connections
	echo -e "\t\t\c"
	read -p "指定 MySQL 数据库最大错误连接数（默认为 50）：" mysql_connections_errors
	echo -e "\t\t\c"
	read -p "指定 MySQL 数据库日志文件目录（默认为 /var/log/mysql）：" mysql_log_dir

	# [[ -d ${mysql_data_dir:-/var/lib/mysql} ]] || \
	# 	mkdir -p ${mysql_data_dir:-/var/lib/mysql}
	# 	chown -R mysql:mysql ${mysql_data_dir:-/var/lib/mysql}
	[[ -d ${mysql_log_dir:-/var/log/mysql} ]] || \
		mkdir -p ${mysql_log_dir:-/var/log/mysql}
		chown -R mysql:mysql ${mysql_log_dir:-/var/log/mysql}

	[[ -f ./packages/mysql/my.cnf ]] && \
		sed -ri "/^datadir/s#(^datadir\s?+=\s?+).*#\1${mysql_data_dir:-/var/lib/mysql}#" ./packages/mysql/my.cnf && \
		sed -ri "/socket/s@(^socket\s?+=\s?+).*@\1${mysql_data_dir:-/var/lib/mysql}/mysql.sock@" ./packages/mysql/my.cnf && \
		sed -ri "/character/s/(.?+character.+\s?+=\s?+).*/\1${mysql_character:-utf8}/" ./packages/mysql/my.cnf && \
		sed -ri "/max_connections/s/(^max_connections\s?+=\s?+).*/\1${mysql_connections:-500}/" ./packages/mysql/my.cnf && \
		sed -ri "/max_connect_errors/s/(^max_connect_errors\s?+=\s?+).*/\1${mysql_connections_errors:-50}/" ./packages/mysql/my.cnf && \
		sed -ri "/log-error/s@(^log-error\s?+=\s?+).*@\1${mysql_log_dir:-/var/log/mysql}/mysqld.log@" ./packages/mysql/my.cnf && \
		/usr/bin/cp -f ./packages/mysql/my.cnf /etc/my.cnf
	
	echo -e "\tMySQL 安装完成\t[\033[32m ok \033[0m]"
	echo -e "\t当前 MySQL 版本为："
	mysql --version |& awk '{ printf "\t\033[33m%s\033[0m\n", $0 }'
	echo -e "\t\033[33mMySQL 配置文件为：/etc/my.cnf\033[0m"
	echo -e "\t\033[33mMySQL 数据文件目录为：${mysql_data_dir:-/var/lib/mysql}\033[0m" 
	echo -e "\t\033[33mMySQL 日志文件目录为：${mysql_log_dir:-/var/log/mysql}\033[0m" 

	echo -e "\n\t是否启动 MySQL 服务并配置开机自启动（y/n）:\c"
	read is_mysql_auto_start
	if [[ ${is_mysql_auto_start} == "y" ]] || [[ ${is_mysql_auto_start} == "Y" ]] || [[ ${is_mysql_auto_start} == "" ]]; then
		systemctl status mysqld &> /dev/null || systemctl enable --now mysqld |& awk '{ printf "\n\t\033[92m%s\033[0m\n", $0 }'
	fi

	echo -e "\n\t\033[95m注意，请使用 Systemd 管理 MySQL 服务，不要使用 root 用户执行 mysql 二进制文件启停 MySQL 服务\033[0m"
	echo -e "\t\033[95m启停服务命令如下：\033[0m"
	echo -e "\t\033[93m启动 MySQL 服务：systemctl start mysqld\033[0m"
	echo -e "\t\033[93m重启 MySQL 服务：systemctl restart mysqld\033[0m"
	echo -e "\t\033[93m停止 MySQL 服务：systemctl stop mysqld\033[0m"

	temporary_password=$(awk '/A temporary password/{ print $NF }' ${mysql_log_dir:-/var/log/mysql}/mysqld.log)
	echo -e "\n\t2）初始化 MySQL 密码"
	echo -e "\t\t\033[95m注意：如果为第一次启动，MySQL 会生成一个随机的密码为：\033[92m${temporary_password}\033[0m"
	echo -e "\t\t\c"
	read -p "是否需要初始化随机密码（y/n）：" is_init_password
	if [[ ${is_init_password} == "y" ]] || [[ ${is_init_password} == "Y" ]] || [[ ${is_init_password} == "" ]]; then

		while true; do

			echo -e "\t\t输入 MySQL root 用户密码（至少 8 位）：\c"
			read -s mysql_root_password
			echo -e "\n\t\t再次输入 MySQL root 用户密码：\c"
			read -s mysql_root_password_verify

			if [[ ${mysql_root_password} -eq ${mysql_root_password_verify} ]]; then
				mysql --connect-expired-password  -hlocalhost -uroot -p${temporary_password} -e \
					"set global validate_password_policy=0; alter user 'root'@'localhost' identified by '${mysql_root_password}'; flush privileges;" |& \
					awk '{ printf "\n\t\t\033[95m%s\033[0m\n", $0 }'
				mysql -hlocalhost -uroot -p${mysql_root_password} -e "select 1;" &> /dev/null && \
					echo -e "\t\t密码重置成功\t[\033[32m ok \033[0m]"
				break
			else
				echo -e "\n\t\t两次输入的密码不一致，重新输入"
				continue
			fi
		done
	fi
}

function install_redis {

	echo -e "5. 安装 Redis 数据库"
	redis-server --version &> /dev/null || yum localinstall -y ./packages/redis/* &> /dev/null

	echo -e "\t1）Redis 基本配置：" 
	echo -e "\t\t\c"
	read -p "输入 Redis 监听地址（可以设置多个监听地址，使用空格隔开，默认为 0.0.0.0）：" redis_bind
	echo -e "\t\t\c"
	read -p "输入 Redis 监听端口号（默认为 6379）：" redis_port
	echo -e "\t\t\c"
	read -p "输入 Redis 客户端最大连接数（默认为 10000）：" redis_maxclients
	echo -e "\t\t\c"
	read -p "输入 Redis 日志级别（可选值：debug、varbose、notice、warning，默认为 notice）：" redis_log_level
	echo -e "\t\t\c"
	read -p "输入 Redis 日志目录（默认为 /var/log/redis/）：" redis_log_dir


	[[ -f /etc/redis.conf ]] && \
		sed -ri "/^bind\s/s#(^bind\s).*#\1${redis_bind:-0.0.0.0}#" /etc/redis.conf && \
		sed -ri "/^port\s/s#(^port\s).*#\1${redis_port:-6379}#" /etc/redis.conf && \
		sed -ri "/^(#\s)?maxclients\s/s@^(#\s)?(maxclients\s).*@\2${redis_maxclients:-10000}@" /etc/redis.conf && \
		sed -ri "/^loglevel\s/s#(^loglevel\s).*#\1${redis_log_level:-notice}#" /etc/redis.conf && \
		sed -ri "/^logfile\s/s#(^logfile\s).*#\1${redis_log_dir:-/var/log/redis}/redis.log#" /etc/redis.conf && \
		echo -e "\t\tRedis 基础配置完成\t[\033[32m ok \033[0m]"

	echo -e "\t2）Redis 持久化配置："
	echo -e "\t\033[96m关于 RDB 和 AOF 持久化模式的选择建议，请参考：\033[0m"
	echo -e "\t\033[96mhttps://redis.io/topics/persistence\033[0m"
	echo -e "\t\t\c"
	read -p "是否开启 RDB 快照模式（y/n，默认为开启）："  is_redis_rdb
	if [[ ${is_redis_rdb} == "y" ]] || [[ ${is_redis_rdb} == "Y" ]] || [[ ${is_redis_rdb} == "" ]]; then
		echo -e "\t\t\c"
		read -p "输入 RDB 快照文件存放目录（默认为 /var/lib/redis）：" redis_rdb_dir
		echo -e "\t\t\c"
		read -p "输入 RDB 数据文件名称（默认为 dump.rdb）：" redis_rdb_file

		sed -ri 's/^#\s?+(save\s\w+\s\w+$)/\1/; s/(^save\s"")/# \1/' /etc/redis.conf
		sed -ri "/^dir\s/s@(^dir\s).*@\1${redis_rdb_dir:-/var/lib/redis}@" /etc/redis.conf
		sed -ri "/^dbfilename/s/(^dbfilename\s).*/\1${redis_rdb_file:-dump.rdb}/" /etc/redis.conf
	elif [[ ${is_redis_rdb} == "n" ]] || [[ ${is_redis_rdb} == "N" ]]; then
		sed -ri 's/(^save\s\w+\s\w+$)/# \1/p; s/^#\s?+(save\s"")/\1/' /etc/redis.conf
	else
		continue
	fi

	echo -e "\t\t\c"
	read -p "是否开启 AOF 持久化模式（y/n，默认为关闭）："  is_redis_aof
	if [[ ${is_redis_aof} == "y" ]] || [[ ${is_redis_aof} == "Y" ]]; then
		echo -e "\t\t\c"
		read -p "输入 AOF 持久化策略（可选值有：always、everysec、no，默认值为 everysec）"：redis_aof_mode
		echo -e "\t\t\c"
		read -p "输入 AOF 持久化文件存放目录（注意，如果开启了 RDB 快照，此目录必须和 RDB 快照文件目录一致，默认为 /var/lib/redis）：" redis_aof_dir
		echo -e "\t\t\c"
		read -p "输入 AOF 持久化文件名称（默认为 appendonly.aof）" redis_aof_file

		sed -ri "/^appendonly\s/s/(^appendonly\s).*/\1yes/" /etc/redis.conf
		sed -ri "/^appendfsync\s/s/(^appendfsync\s).*/\1${redis_aof_mode:-everysec}/" /etc/redis.conf
		sed -ri "/^dir\s/s@(^dir\s).*@\1${redis_aof_dir:-/var/lib/redis}@" /etc/redis.conf
		sed -ri "/^appendfilename/s/(^appendfilename\s).*/\1\"${redis_aof_file:-appendonly.aof}\"/" /etc/redis.conf
	else
		sed -ri "/^appendonly\s/s/(^appendonly\s).*/\1no/" /etc/redis.conf
	fi

	echo -e "\t3）Redis 安全配置："
	echo -e "\t\t\c"
	read -p "是否开启保护模式，开启保护模式后如果未设置监听地址或者密码，只能使用 127.0.0.1 访问 Redis（y/n，默认为开启）" is_redis_protected_mode
	if [[ ${is_redis_protected_mode} == "n" ]] || [[ ${is_redis_protected_mode} == "N" ]]; then
		sed -ri "/^protected-mode\s/s/(^protected-mode\s).*/\1no/" /etc/redis.conf
	else
		sed -ri "/^protected-mode\s/s/(^protected-mode\s).*/\1yes/" /etc/redis.conf 
	fi

	echo -e "\t\t\c"
	read -p "是否设置 Redis 客户端连接密码（y/n，默认无密码）：" is_redis_requirepass
	if [[ ${is_redis_requirepass} == "y" ]] || [[ ${is_redis_requirepass} == "Y" ]]; then
		while true; do
			echo -e "\t\t\c"
			read -p "输入 Redis 客户端连接密码：" redis_requirepass
			echo -e "\t\t\c"
			read -p "再次输入 Redis 客户端连接密码：" redis_requirepass_verify
			if [[ ${redis_requirepass} -eq ${redis_requirepass_verify} ]]; then
				sed -ri "s/^#?+\s?+(requirepass\s).*/\1${redis_requirepass}/" /etc/redis.conf
				break
			else
				echo -e "\n\t\t两次输入的密码不一致，重新输入"
				continue
			fi
		done
	else
		sed -ri "s/^(requirepass\s.*)/# \1/" /etc/redis.conf
	fi

	echo -e "\tRedis 安装完成\t[\033[32m ok \033[0m]"
	echo -e "\t当前 Redis 版本为："
	redis-server --version |& awk '{ printf "\t\033[33m%s\033[0m\n", $0 }'
	echo -e "\t\033[33mRedis 配置文件为：/etc/redis.conf\033[0m"
	echo -e "\t\033[33mRedis 日志文件目录为：${redis_log_dir:-/var/log/redis}/redis.log\033[0m" 

	echo -e "\n\t是否启动 Redis 服务并配置开机自启动（y/n）:\c"
	read is_redis_auto_start
	if [[ ${is_redis_auto_start} == "y" ]] || [[ ${is_redis_auto_start} == "Y" ]] || [[ ${is_redis_auto_start} == "" ]]; then
		systemctl status redis &> /dev/null || systemctl enable --now redis |& awk '{ printf "\n\t\033[92m%s\033[0m\n", $0 }'
	fi

	echo -e "\n\t\033[95m注意，请使用 Systemd 管理 Redis 服务，不要使用 root 用户执行 Redis 二进制文件启停 Redis 服务\033[0m"
	echo -e "\t\033[95m启停服务命令如下：\033[0m"
	echo -e "\t\033[93m启动 Redis 服务：systemctl start redis\033[0m"
	echo -e "\t\033[93m重启 Redis 服务：systemctl restart redis\033[0m"
	echo -e "\t\033[93m停止 Redis 服务：systemctl stop redis\033[0m"
}

os=$(awk '{ print $1 }' /etc/centos-release)

if [[ ${os} == "CentOS" ]]; then

	while true; do

		echo -e "\n安装服务列表："
		echo -e "+--------------------------------------------------------------+"
		echo -e "| 服务列表        　　                                         |"
		echo -e "+--------------------+--------------------+--------------------+"
		echo -e "| 1. Java            | 　2. Tomcat　      | 3. Nginx           |"
		echo -e "+--------------------+--------------------+--------------------+"
		echo -e "| 4. MySQL           |   5. Redis         |                    |"
		echo -e "+--------------------+--------------------+--------------------+"

		echo -e "\n输入数字选择安装的服务（ 输入 a 选择所有，输入 q 退出）：\c"
		read num
		case ${num} in
			1 ) 
				install_java
				;;
			2 )
				install_tomcat
				;;
			3 ) 
				install_nginx
				;;
			4 )
				install_mysql
				;;
			5 )
				install_redis
				;;
			a ) 
				install_java
				install_tomcat
				install_nginx
				install_mysql
				install_redis
				;;
			q ) 
				break
				;;
			* )
				echo -e "找不到要配置的功能，请重新输入"
				;;
		esac

	done

else
	echo -e "[ 系统不符合要求，请检查系统 ]"
fi