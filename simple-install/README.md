**此脚本安装服务使用的是本地安装：**

```bash
$ yum localinstall -y
```

需要提前准备好安装包，准备过程如下：

1. 启动个 CentOS 7 的容器

2. 在容器内开启 Yum 缓存

3. 在容器内使用 Yum 安装指定服务

4. 在缓存中寻找 Rpm 文件并保存到指定的目录中

5. 将目录拷贝至宿主机上

例如我这个脚本使用的安装目录为：

```
tree  ./packages/
packages/
├── java
│   ├── jdk-8u202-linux-x64.tar.gz
│   └── server-jre-8u202-linux-x64.tar.gz
├── mysql
│   ├── groff-base-1.22.2-8.el7.x86_64.rpm
│   ├── libaio-0.3.109-13.el7.x86_64.rpm
│   ├── my.cnf
│   ├── mysql-community-client-5.7.25-1.el7.x86_64.rpm
│   ├── mysql-community-common-5.7.25-1.el7.x86_64.rpm
│   ├── mysql-community-libs-5.7.25-1.el7.x86_64.rpm
│   ├── mysql-community-server-5.7.25-1.el7.x86_64.rpm
│   ├── net-tools-2.0-0.24.20131004git.el7.x86_64.rpm
│   ├── numactl-libs-2.0.9-7.el7.x86_64.rpm
│   ├── perl-5.16.3-294.el7_6.x86_64.rpm
│   ├── perl-Carp-1.26-244.el7.noarch.rpm
│   ├── perl-constant-1.27-2.el7.noarch.rpm
│   ├── perl-Encode-2.51-7.el7.x86_64.rpm
│   ├── perl-Exporter-5.68-3.el7.noarch.rpm
│   ├── perl-File-Path-2.09-2.el7.noarch.rpm
│   ├── perl-File-Temp-0.23.01-3.el7.noarch.rpm
│   ├── perl-Filter-1.49-3.el7.x86_64.rpm
│   ├── perl-Getopt-Long-2.40-3.el7.noarch.rpm
│   ├── perl-HTTP-Tiny-0.033-3.el7.noarch.rpm
│   ├── perl-libs-5.16.3-294.el7_6.x86_64.rpm
│   ├── perl-macros-5.16.3-294.el7_6.x86_64.rpm
│   ├── perl-parent-0.225-244.el7.noarch.rpm
│   ├── perl-PathTools-3.40-5.el7.x86_64.rpm
│   ├── perl-Pod-Escapes-1.04-294.el7_6.noarch.rpm
│   ├── perl-podlators-2.5.1-3.el7.noarch.rpm
│   ├── perl-Pod-Perldoc-3.20-4.el7.noarch.rpm
│   ├── perl-Pod-Simple-3.28-4.el7.noarch.rpm
│   ├── perl-Pod-Usage-1.63-3.el7.noarch.rpm
│   ├── perl-Scalar-List-Utils-1.27-248.el7.x86_64.rpm
│   ├── perl-Socket-2.010-4.el7.x86_64.rpm
│   ├── perl-Storable-2.45-3.el7.x86_64.rpm
│   ├── perl-Text-ParseWords-3.29-4.el7.noarch.rpm
│   ├── perl-threads-1.87-4.el7.x86_64.rpm
│   ├── perl-threads-shared-1.43-6.el7.x86_64.rpm
│   ├── perl-Time-HiRes-1.9725-3.el7.x86_64.rpm
│   └── perl-Time-Local-1.2300-2.el7.noarch.rpm
├── nginx
│   ├── make-3.82-23.el7.x86_64.rpm
│   ├── nginx-1.14.2-1.el7_4.ngx.x86_64.rpm
│   ├── openssl-1.0.2k-16.el7_6.1.x86_64.rpm
│   └── openssl-libs-1.0.2k-16.el7_6.1.x86_64.rpm
├── redis
│   ├── logrotate-3.8.6-17.el7.x86_64.rpm
│   └── redis-5.0.4-1.el7.remi.x86_64.rpm
└── tomcat
    ├── apache-tomcat-8.5.40.tar.gz
    └── tomcat.service
```