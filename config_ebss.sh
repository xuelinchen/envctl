#!/bin/bash

######################################
# 
# 脚本名称: config_ebss.sh
#
# 描述：
#       配置业务支撑系统脚本
# 返回：
#		0. 成功
#		1. 脚本错误
#		2. 环境检查失败
#
# 作者: chenxuelin@emicnet.com
# 下载脚本
#   curl -LO http://10.0.0.29/envctl/config_ebss.tar && tar -zxf config_ebss.tar
# 配置mysql
#   ./config_ebss.sh mysql
#
######################################

# 声明脚本变量
__ScriptFullName=$(readlink -f $0)  
__ScriptName=$(basename $__ScriptFullName)
__ScriptDir=$(dirname $__ScriptFullName)
__ScriptVersion='envctl-20180518160826'
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
# 获取配置文件参数值
# 支持格式
#   key=value
#   kye = value
# ----------------------------
get_config_value(){
#   sed -n -r "/^[\s]?DB_HOST/p"  /usr/local/EmicallApp/config/boot.cfg | awk -F '=' '{print $2}'
#   awk -F "=>" '{if($1 ~ /session/){a=1;b=0};if(a==1){if($1 ~ /\]/){exit 99};if($1 ~ /prefix/){print $2;exit 0;}}}' /home/cxl/git-svn/spi/spi-php/application/config.php
#   awk -F '=>' '{if($0~/\047session\047/){find=1;fl=0;fr=0}if(find){if($0~/\[/){fl++;};if($0~/\]/){fr++;};if($1~/\047host\047/){print $2;exit 0;}if(fl==fr){exit 99}}}' ../application/config.php
    if [ -z "$1" ]; then return 1; fi
    if [ ! -f "$1" ]; then return 1; fi
    if [ -z "$2" ]; then return 2; fi
    local fn="$1"
    local fKey="$2"
    cat "$fn" | grep "$fKey\s*=" | cut -d "=" -f 2  
}
# ----------------------------
# 设置配置文件参数值
# 支持格式
#   key=value
#   key = value
# ----------------------------
set_config_value(){
    if [ -z "$1" ]; then return 1; fi
    if [ ! -f "$1" ]; then return 1; fi
    if [ -z "$2" ]; then return 2; fi
    local fn="$1"
    local fKey="$2"
    local fVal="$3"
    if [ -z "$3" ]; then fVal=''; fi
    sed -ri "s/($fKey\s*=).*/\1 $fVal/" "$fn"
}
# ----------------------------
# 配置mysql
# ---------------------------- 
config_mysql(){
    local status=1
    is_install "mysql-common" && status=0 || status=1
    if [ $status = 0 ]; then
        #cxl_log "配置mysql参数，主从库参数等，暂时使用缺省参数" info
        cxl_log "配置mysql允许远程方法" info
        mysqlConfile='/etc/mysql/mysql.conf.d/mysqld.cnf'
        cat $mysqlConfile | grep "#bind-address" && status=0 || status=1
        if [ "$status" -gt 0 ]; then
            sed -i 's/bind-address/#bind-address/' "$mysqlConfile"
        fi
        mysql -u root -p"${mysql_root_pass}" -e "grant all privileges  on *.* to root@'%' identified by '${mysql_root_pass}';flush privileges;"
    else
        cxl_log "未安装mysql，跳过配置" "warn"
    fi
    return 0
}

# ----------------------------
# 配置redis
# ---------------------------- 
config_redis(){
    is_install "redis-server" && status=0 || status=1
    if [ $status = 0 ]; then
        cxl_log "配置redis参数，暂时不配置" info
    else
        cxl_log "未安装redis，跳过配置" "warn"
    fi
}

# ----------------------------
# 配置nginx
# ---------------------------- 
config_nginx(){
    is_install "nginx" && status=0 || status=1
    if [ $status = 0 ]; then
        cxl_log "拷贝证书文件" "warn"
        if [ ! -d '/etc/nginx/crt' ]; then mkdir /etc/nginx/crt -p; fi
        cp crt/* /etc/nginx/crt -rf
        cxl_log "配置发布文件" "warn"
        local nginxproxypass=''
        if [ -z "$nginx_proxy_addr" ]; then nginx_proxy_addr='127.0.0.1:1067'; fi
        for server in `echo "$nginx_proxy_addr"|sed "s/,/ /g"`
        do
            if [ -z "$nginxproxypass" ] ; then
                nginxproxypass="server $server weight=1;"
            else
                nginxproxypass="$nginxproxypass\nserver $server weight=1;"
            fi
        done
        cp res/nginx_ssl.conf nginx_bss.conf
        sed -i "s/NGINXPROXYPASSADDR/$nginxproxypass/g" nginx_bss.conf
        sed -i "s/NGINXPUBLISHPORT/2013/g" nginx_bss.conf
        cxl_log "拷贝发布文件到发布目录" "warn"
        cp nginx_bss.conf /etc/nginx/sites-available/nginx_bss.conf -rf
        if [ ! -f "/etc/nginx/sites-enabled/nginx_bss.conf" ]; then
            ln -s /etc/nginx/sites-available/nginx_bss.conf /etc/nginx/sites-enabled/nginx_bss.conf
        fi
        rm nginx_bss.conf -f
        cxl_log "重启nginx" info
        service nginx restart
    else
        cxl_log "未安装nginx，跳过配置" "warn"
    fi
}


# ----------------------------
# 配置apache
# ---------------------------- 
config_apache(){
    is_install "apache2" && status=0 || status=1
    if [ $status = 0 ]; then
        local publicDir='/var/www/ebss/public'
        cxl_log "创建发布目录" "warn"
        mkdir ${publicDir} -p
        cxl_log "配置发布文件" "warn"
        local apache_publish_port=1067
        cxl_log "删除443，80端口避免与nginx冲突，添加监听$apache_publish_port" info
        #sed -ri "/Listen\s*(443|80|$apache_publish_port|1071)/d" /etc/apache2/ports.conf
        sed -ri "/Listen\s*(443|80|$apache_publish_port)/d" /etc/apache2/ports.conf
        echo "Listen $apache_publish_port" >>/etc/apache2/ports.conf
        
        cp res/apache.conf apache_bss.conf
        sed -i "s/APACHEPUBLISHPORT/$apache_publish_port/g" apache_bss.conf
        sed -i "s#APACHEPUBLISHDIR#${publicDir}#g" apache_bss.conf
    
        cxl_log "拷贝发布文件到发布目录" "warn"
        cp apache_bss.conf /etc/apache2/sites-available/apache_bss.conf -rf
        if [ ! -f "/etc/apache2/sites-enabled/apache_bss.conf" ]; then
            ln -s /etc/apache2/sites-available/apache_bss.conf /etc/apache2/sites-enabled/apache_bss.conf
        fi
        rm apache_bss.conf -f
        chown www-data:www-data "${publicDir}" -R
        chmod 777 "${publicDir}" -R
        cxl_log "重启apache2" info
        service apache2 restart
    else
        cxl_log "未安装apache，跳过配置" "warn"
    fi
}

# ----------------------------
# 配置php
# ---------------------------- 
config_php(){
    is_install "php7.0" && status=0 || status=1
    if [ $status != 0 ]; then cxl_log "未安装php7.0，跳过配置"; return 1; fi
    cxl_log "准备安装进程管理工具supervisor" "info"
    check_and_install_soft supervisor && status=0 || status=1
    cxl_log "安装supervisor已完成" info
    
    cxl_log "准备安装转码工具lame" "info"
    check_and_install_soft lame && status=0 || status=1
    cxl_log "安装lame已完成" info
    php_fpm_phpini="/etc/php/7.0/fpm/php.ini"
    if [ -f "$php_fpm_phpini" ]; then
        cxl_log "开始配置$php_fpm_phpini最大执行时间max_execution_time=150秒" info
        local max_execution_time=`get_config_value "$php_fpm_phpini" "max_execution_time"`
        if [ -z "$max_execution_time" ]; then
            echo "max_execution_time=150" >> "$php_fpm_phpini"
        else
            set_config_value "$php_fpm_phpini" "max_execution_time" "150"
        fi
        cxl_log "开始配置$php_fpm_phpini页面接收数据时间max_input_time=150秒" info
        local max_input_time=`get_config_value "$php_fpm_phpini" "max_input_time"`
        if [ -z "$max_input_time" ]; then
            echo "max_input_time=150" >> "$php_fpm_phpini"
        else
            set_config_value "$php_fpm_phpini" "max_input_time" "150"
        fi
        #cxl_log "开始配置$php_fpm_phpini页面内存数memory_limit=128M" info
        #local max_input_time=`get_config_value "$php_fpm_phpini" "memory_limit"`
        #if [ -z "$memory_limit" ]; then
        #    echo "memory_limit=128M" >> "$php_fpm_phpini"
        #else
        #    set_config_value "$php_fpm_phpini" "memory_limit" "128M"
        #fi
        cxl_log "开始配置$php_fpm_phpini最大上传文件大小upload_max_filesize=100M" info
        local upload_max_filesize=`get_config_value "$php_fpm_phpini" "upload_max_filesize"`
        if [ -z "$upload_max_filesize" ]; then
            echo "upload_max_filesize=100M" >> "$php_fpm_phpini"
        else
            set_config_value "$php_fpm_phpini" "upload_max_filesize" "100M"
        fi
        cxl_log "开始配置$php_fpm_phpini最大POST数据大小post_max_size=100M" info
        local post_max_size=`get_config_value "$php_fpm_phpini" "post_max_size"`
        if [ -z "$post_max_size" ]; then
            echo "post_max_size=100M" >> "$php_fpm_phpini"
        else
            set_config_value "$php_fpm_phpini" "post_max_size" "100M"
        fi
        cxl_log "开始配置$php_fpm_phpini会话保存handle" info
        set_config_value "$php_fpm_phpini" "session.save_handler" "user"
    fi
    php_cli_phpini="/etc/php/7.0/cli/php.ini"
    if [ -f "$php_cli_phpini" ]; then
        cxl_log "开始配置$php_cli_phpini最大执行时间max_execution_time=600秒" info
        local max_execution_time=`get_config_value "$php_cli_phpini" "max_execution_time"`
        if [ -z "$max_execution_time" ]; then
            echo "max_execution_time=600" >> "$php_cli_phpini"
        else
            set_config_value "$php_cli_phpini" "max_execution_time" "600"
        fi
        #cxl_log "开始配置$php_cli_phpini脚本消费内存数memory_limit=256M" info
        #local max_input_time=`get_config_value "$php_cli_phpini" "memory_limit"`
        #if [ -z "$memory_limit" ]; then
        #    echo "memory_limit=256M" >> "$php_cli_phpini"
        #else
        #    set_config_value "$php_cli_phpini" "memory_limit" "256M"
        #fi
    fi
}

# ----------------------------
# 配置all
# ---------------------------- 
config_all(){
    config_mysql
    config_redis
    config_nginx
    config_apache
    config_php
}

is_ubuntu 16.04 && status=0 || status=1
if [  "$status" -gt 0 ]; then cxl_log "当前系统非ubuntu 16.04，此安装程序只在ubuntu16.04上做过测试" "error"; return 2; fi

# 功能变量
mysql_root_pass='C1oudP8x&2017'
nginx_proxy_addr='127.0.0.1:1067'

soft='version'
if [ -n "$1" ]; then soft="$1"; fi
if [ -n "$2" ]; then mysql_root_pass="$2"; fi
if [ -n "$3" ]; then nginx_proxy_addr="$3"; fi

case "$soft" in
    -h | --help | help | -v | --version | version)
         echo  "$__ScriptName -- 版本 $__ScriptVersion "
         echo  "$__ScriptName  all|mysql|nginx|apache|redis|php "
         exit 0
    ;;
     *)
        cxl_log "---------start config software $soft----------" 
        eval "config_$soft" && status=0 || status=1
        if [ "$status" -gt 0 ]; then cxl_log "不支持配置此软件" "error";exit 3; fi
        cxl_log "*********end config***********"
     ;;
esac
