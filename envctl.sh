#!/bin/bash

######################################
# 
# 脚本名称: envctl.sh
#
# 描述：
#       安装或清理系统软件
# 返回：
#		0. 成功
#		1. 脚本错误
#		2. 环境检查失败
#
# 作者: chenxuelin@emicnet.com
# curl -ksLO https://10.0.0.42:1068/espackage.tar.gz &&  openssl des3 -d -k emicnet789 -salt -in espackage.tar.gz | tar xzf - && ./esctl.sh https://bss.emicnet.com 1
# 下载脚本
#   curl -LO http://10.0.0.29/envctl/envctl.sh
# 安装mysql
#   curl -LO http://10.0.0.29/envctl/envctl.sh && ./envctl.sh install mysql
# 卸载mysql
#   curl -LO http://10.0.0.29/envctl/envctl.sh && chmod 777 * && ./envctl.sh remove mysql
#
######################################

# 声明脚本变量
__ScriptFullName=$(readlink -f $0)  
__ScriptName=$(basename $__ScriptFullName)
__ScriptDir=$(dirname $__ScriptFullName)
__ScriptVersion='envctl-20180224171815'
__CurrentUser=$(whoami)
__LogPath=$__ScriptDir/log/envctl/
__LogFile=$__LogPath`date +'%Y%m%d'`.log

# 创建目录
if [ ! -d "$__ScriptDir/log/envctl/" ]; then
    mkdir "$__ScriptDir/log/envctl/" -p
fi

# ----------------------------
# 记录log文件并打印到屏幕
# ----------------------------
cxl_log(){
    if [ -z "$1" ]; then return 1; fi
    local logDate=`date +'%Y-%m-%d %H:%M:%S'`
    local level="debug"
    if [ -n "$2" ] ; then level="$2"; fi
    level=$(echo $level | tr [:lower:] [:upper:])
    # 删除7天前的log文件
    find $__LogPath*.log -mtime 7 -delete 
    local status=1
    echo -e "$level $logDate $1" >> $__LogFile && status=0 || status=1
    echo -e "$1"
    return $status
}

# ----------------------------
# 判断系统是否ubuntu
# ----------------------------
is_ubuntu(){
    # 检查版本号，如果为空则不检查
    local ckVersion="" 
    if [ -n "$1" ] ; then ckVersion="$1"; fi
    local curSys=`lsb_release -i | awk '{print $3}'`
    if [ x"$curSys" = x"Ubuntu" ] 
    then
        if [ ! -z "$ckVersion" ] 
        then
            local curVer=`lsb_release -r|awk '{print $2}'|grep "$ckVersion"`
            if [ -z "$curVer" ] ; then return 1; fi
        fi
        return 0
    fi
    return 1
}
# ----------------------------
# 检查是否安装软件
# ----------------------------
is_install(){
    if [ -z "$1" ] ; then return 1; fi
    local status=0
    local softName="$1"
    dpkg -s "$softName" >/dev/null && status=0 || status=1
    return $status
}
# ----------------------------
# 安装软件
# ----------------------------
install_soft(){
    if [ -z "$1" ] ; then return 1; fi
    local status=0
    apt install  "$1" -y && status=0 || status=1 
    return $status
}
# ----------------------------
# 检查软件是否存在，如果不存在安装软件
# ----------------------------
check_and_install_soft(){
    if [ -z "$1" ] ; then return 1; fi
    local softName="$1"
    local status=0
    is_install "$softName" && status=0 || status=1
    if [ $status != 0 ]; then
        install_soft "$softName" && status=0 || status=1
        if [ $status != 0 ];  then 
            cxl_log "安装$softName失败" "error"
        else
            cxl_log "安装$softName成功" "info"
        fi
    else
        cxl_log "$softName已安装，跳过安装" "warn"
    fi
    return $status
}
# ----------------------------
# 卸载软件
# ----------------------------
remove_soft(){
    if [ -z "$1" ] ; then return 1; fi
    local status=0
    apt autoremove "$1" --purge  -y && status=0 || status=1
    return $status
}
# ----------------------------
# 检查软件是否存在，如果存在卸载软件
# ----------------------------
check_and_remove_soft(){
    if [ -z "$1" ] ; then return 1; fi
    local softName="$1"
    local status=1
    is_install "$softName" && status=0 || status=1
    if [ $status = 0 ]; then
        cxl_log "准备卸载$softName" "info"
        remove_soft "$softName" && status=0 || status=1
        if [ $status != 0 ]; then 
            cxl_log "卸载$softName失败" "error"
        else
            cxl_log "卸载$softName成功" "info"
        fi
    else
        cxl_log "未安装$softName，跳过卸载" "warn"
    fi
    return $status
}

# ----------------------------
# 安装mysql
# ---------------------------- 
install_mysql(){
    cxl_log "准备安装ubuntu静默安装工具debconf-utils" "info"
    check_and_install_soft debconf-utils && status=0 || status=1
    if [ $status -gt 0 ]; then
        cxl_log "安装debconf-utils失败,退出程序，请手工安装debconf-utils，再次运行此脚本" "error"
        exit 4
    else
        cxl_log "设置静默安装参数" info
        #echo ${mysql_root_pass}
        if [ -f debparamter.conf ]; then 
            echo "find file"
            rm debparamter.conf
        fi
        echo "mysql-server mysql-server/root_password password ${mysql_root_pass}" > debparamter.conf
        echo "mysql-server mysql-server/root_password_again password ${mysql_root_pass}" >> debparamter.conf
        debconf-set-selections debparamter.conf
        rm debparamter.conf
    fi
    cxl_log "安装debconf-utils已完成" info
    check_and_install_soft mysql-server
    apt install libmysqlclient-dev -y
    cxl_log "配置mysql编码为utf8_unicode_ci"
    rm /etc/mysql/mysql.conf.d/mysqlutf8.cnf -f
    cat>/etc/mysql/mysql.conf.d/mysqlutf8.cnf<<EOF
# add by cxl, set mysql character is utf8 and collation is utf8_unicode_ci
[client]
default-character-set = utf8

[mysqld]
init_connect = 'set names utf8'
init_connect = 'set collation_connection = utf8_unicode_ci'
character-set-server = utf8
collation-server = utf8_unicode_ci
skip-character-set-client-handshake
EOF
    service mysql restart
}
# ----------------------------
# 卸载mysql
# ---------------------------- 
remove_mysql(){
    check_and_remove_soft mysql-common && status=0 || status=1  
    if [ $status = 0 ]; then        
        cxl_log "删除mysql配置文件和库文件" "warn"
        # 删除配置文件
        rm /etc/mysql -rf 
        # 删除库文件
        rm /var/lib/mysql -rf
    fi
    cxl_log "卸载mysql已完成" "info"
}
# ----------------------------
# 安装redis
# ---------------------------- 
install_redis(){
    check_and_install_soft redis-server
    cxl_log "安装redis已完成" info
}
# ----------------------------
# 卸载redis
# ---------------------------- 
remove_redis(){
    check_and_remove_soft redis-server && status=0 || status=1
    if [ $status = 0 ]; then cxl_log "删除redis配置文件" "info" ; rm /etc/redis -rf; fi
    cxl_log "卸载redis-server已完成" "info"    
}
# ----------------------------
# 安装nginx
# ---------------------------- 
install_nginx(){
    check_and_install_soft nginx
    cxl_log "安装nginx已完成" info
}
# ----------------------------
# 卸载nginx
# ---------------------------- 
remove_nginx(){
    check_and_remove_soft nginx-common && status=0 || status=1
    if [ $status = 0 ]; then cxl_log "删除nginx配置文件" "warn" ; rm /etc/nginx -rf; fi
    cxl_log "卸载nginx已完成" "info" 
}

# ----------------------------
# 安装apache
# ---------------------------- 
install_apache(){
    check_and_install_soft apache2
    cxl_log "安装apache已完成" info
    cxl_log "停止apache模块mpm_event,mpm_prefork,打开mpm_worker,rewrite,proxy_fcgi" info
    a2dismod mpm_event
    a2dismod mpm_prefork
    a2enmod mpm_worker rewrite proxy_fcgi
}
# ----------------------------
# 卸载apache
# ---------------------------- 
remove_apache(){
    check_and_remove_soft apache2 && status=0 || status=1
    if [ $status = 0 ]; then cxl_log "删除apache2配置文件" "warn" ; rm /etc/apache2 -rf; fi
    cxl_log "卸载apache2已完成" "info"
}

# ----------------------------
# 安装php
# ---------------------------- 
install_php(){
    check_and_install_soft php7.0 && status=0 || status=1
    if [ $status != 0 ]; then
        cxl_log "php7.0安装失败，跳过安装依赖库" "error"
    else
        print_log "准备安装php7.0依赖库" "info"
        check_and_install_soft php7.0-curl
        check_and_install_soft php7.0-mbstring
        check_and_install_soft php7.0-gd
        check_and_install_soft php7.0-mysql
        check_and_install_soft php-redis
        check_and_install_soft mcrypt
        check_and_install_soft libmcrypt-dev
        check_and_install_soft php-mcrypt
        check_and_install_soft php7.0-bcmath
        #check_and_install_soft libapache2-mod-fastcgi
        cxl_log "停止apache模块php7.0，启用php7.0-fpm配置文件" 'info'
        a2dismod php7.0
        a2enconf php7.0-fpm
    fi
}
# ----------------------------
# 卸载php
# ---------------------------- 
remove_php(){
    check_and_remove_soft libapache2-mod-php7.0
    check_and_remove_soft libapache2-mod-fastcgi
    check_and_remove_soft php7.0-mysql
    check_and_remove_soft php-common && status=0 || status=1
    cxl_log "卸载php7.0已完成" "info"
    if [ $status = 0 ]; then cxl_log "删除php7.0配置文件" "warn" ; rm /etc/php -rf; fi
}

# ----------------------------
# 安装all
# ---------------------------- 
install_all(){
    install_mysql
    install_redis
    install_nginx
    install_apache
    install_php
}
# ----------------------------
# 卸载all
# ---------------------------- 
remove_all(){
    remove_redis
    remove_nginx
    remove_php
    remove_apache
    remove_mysql
}
is_ubuntu 16.04 && status=0 || status=1
if [  "$status" -gt 0 ]; then cxl_log "当前系统非ubuntu 16.04，此安装程序只在ubuntu16.04上做过测试" "error"; return 2; fi

# 功能变量
mysql_root_pass='C1oudP8x&2017'

action='version'
if [ -n "$1" ]; then action="$1"; fi
soft='all'
if [ -n "$2" ]; then soft="$2"; fi
if [ -n "$3" ]; then mysql_root_pass="$3"; fi

case "$action" in
    -h | --help | help | -v | --version | version)
         echo  "$__ScriptName -- 版本 $__ScriptVersion "
         echo  "$__ScriptName install all|mysql|nginx|apache|redis|php "
         echo  "$__ScriptName clear all|mysql|nginx|apache|redis|php "
         exit 0
    ;;
    install)
        cxl_log "---------start install software $soft----------" 
        check_and_install_soft jq && status=0 || status=1
        eval "install_$soft" && status=0 || status=1
        if [ "$status" -gt 0 ]; then cxl_log "不支持安装此软件" "error"; fi
        cxl_log "*********end install***********"
     ;;
    remove)
        cxl_log "---------start remove software $soft----------"
        eval "remove_$soft" && status=0 || status=1
        if [ "$status" -gt 0 ]; then cxl_log "不支持卸载此软件" "error"; fi
        cxl_log "*********end remove***********"
     ;;
     *)
        cxl_log "不支持此操作:$action"
        exit 3
     ;;
esac
