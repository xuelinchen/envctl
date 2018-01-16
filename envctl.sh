#!/bin/bash

######################################
# 
# 脚本名称: envctl.sh
#
# 描述：服务器安装卸载软件脚本
#      1. 静默安装软件
#      2. 完全卸载软件，包括数据
#      
# Usage :  ${__ScriptName} [ACTION]  [OPTION] ...  
#     
#  
# ACTION：
#  
#  help     查看帮助
#  version  查看脚本版本
#  installEnv  安装服务器依赖软件
#  clearEnv  删除服务器依赖软件（自动清除所有依赖软件）
#
#  
# Options：
#  相关参数
#  -h, --help  显示帮助
#  -v, --version  显示脚本版本
#  --with-nginx=1  
#  --with-apache=1  安装apache（安装时生效）大于0为安装0为不安装，缺省安装
#  --with-mysql=1  安装mysql（安装时生效）大于0为安装0为不安装，缺省安装
#  --with-mysql-port=3306  系统mysql端口，缺省3306
#  --with-mysql-user=root  系统mysql用户名，缺省root
#  --with-mysql-pass=C1oudP8x\\\&2017  系统mysql密码，缺省C1oudP8x&2017
#  --with-mysql-root-pass=C1oudP8x\\\&2017  mysql root密码，缺省C1oudP8x&2017
#  --with-redis=1  安装redis（安装时生效）大于0为安装0为不安装，缺省安装
#  --with-redis-uri='127.0.0.1'  redis服务器ip地址,缺省127.0.0.1
# 
# 返回：
#		0. 成功
#		1. 脚本错误
#		2. 环境检查失败
#
# 作者: chenxuelin@emicnet.com
# 
######################################

# 声明脚本变量
__ScriptFullName=$(readlink -f $0)  
__ScriptName=$(basename $__ScriptFullName)
__ScriptDir=$(dirname $__ScriptFullName)
__ScriptVersion="envctl-2018.01.15" 
__CurrentUser=$(whoami)

# 检查辅助类是否存在
_helperFile="$__ScriptDir/helper.sh"
_cxlLogFile="$__ScriptDir/shell-baselib/cxl_log"
_cxlSystemFile="$__ScriptDir/shell-baselib/cxl_system"
_cxlPrintFile="$__ScriptDir/shell-baselib/cxl_print"
_cxlStringFile="$__ScriptDir/shell-baselib/cxl_string"
_cxlCliFile="$__ScriptDir/shell-baselib/cxl_cli"
_cxlUtilsFile="$__ScriptDir/shell-baselib/cxl_utils"
_defaultConf="$__ScriptDir/default.conf"

if [ ! -f "$_cxlSystemFile" ]; then echo "文件$_cxlSystemFile不存在，退出脚本"; exit 1; fi
if [ ! -f "$_cxlLogFile" ]; then echo "文件$_cxlLogFile不存在，退出脚本"; exit 1; fi
if [ ! -f "$_cxlPrintFile" ]; then echo "文件$_cxlPrintFile不存在，退出脚本"; exit 1; fi
if [ ! -f "$_cxlStringFile" ]; then echo "文件$_cxlStringFile不存在，退出脚本"; exit 1; fi
if [ ! -f "$_cxlCliFile" ]; then echo "文件$_cxlCliFile不存在，退出脚本"; exit 1; fi
if [ ! -f "$_cxlUtilsFile" ]; then echo "文件$_cxlUtilsFile不存在，退出脚本"; exit 1; fi
if [ ! -f "$_helperFile" ]; then echo "文件$_helperFile不存在，退出脚本"; exit 1; fi

# 包含必要文件
. "$_cxlLogFile"
. "$_cxlSystemFile"
. "$_cxlPrintFile"
. "$_cxlStringFile"
. "$_cxlCliFile"
. "$_cxlUtilsFile"
. "$_helperFile"

checkEnv
status=$?
if [ "$status" -gt 0 ]; then print_log "环境检查失败，退出脚本" "error" ; exit 2; fi

# log文件名
cxl_log_file="envctl.log"
# 检查日志文件，超过5M只保留最后1000行
check_log_file

#-----------------------------------------------------------------------  
# FUNCTION: usage  
# DESCRIPTION:  Display usage information.  
#-----------------------------------------------------------------------  
usage() {  
	cat <<EOT
	
Usage :  ${__ScriptName} [ACTION]  [OPTION] ...  
  环境安装脚本
  
ACTION：
  环境安装脚本
  help --help -h     显示帮助
  version --version -v  显示脚本版本
  installEnv  安装服务器依赖软件
  clearEnv  删除服务器依赖软件（自动清除所有依赖软件）
  
Options：
  相关参数
  --with-nginx=1  安装nginx（安装时生效）大于0为安装0为不安装，缺省安装
  --with-apache=1  安装apache（安装时生效）大于0为安装0为不安装，缺省安装
  --with-mysql=1  安装mysql（安装时生效）大于0为安装0为不安装，缺省安装
  --with-mysql-host=localhost  spi系统mysql地址，缺省localhost
  --with-mysql-port=3306  系统mysql端口，缺省3306
  --with-mysql-user=root  系统mysql用户名，缺省root
  --with-mysql-pass=C1oudP8x\&2017  系统mysql密码，缺省C1oudP8x&2017
  --with-mysql-root-pass=C1oudP8x\&2017  mysql root密码，缺省C1oudP8x&2017
  --with-redis=1  安装redis（安装时生效）大于0为安装0为不安装，缺省安装
 
返回：
  0. 成功
  1. 脚本错误
  2. 环境检查失败
  
EOT
}   

if [ "$#" -eq 0 ]; then usage; exit 1; fi  

# define variable
action="$1"
shift
if [ -f "$_defaultConf" ]; then . "$_defaultConf"; fi

# parse options
RET=`getopt -o hv --long help,version,with-nginx:,\
with-apache:,with-mysql:,with-mysql-user:,with-mysql-port:,with-mysql-host:,\
with-mysql-pass:,with-mysql-root-pass:,with-redis: \
-n "* ERROR" --  "$@"`
eval "set  -- $RET"  
while true; do	
	case "$1" in  
		-h|--help ) action='help'; break ;; 
		-v|--version ) action='version'; break ;;  
		--with-nginx)  install_nginx=$2; shift 2 ;;
		--with-nginx-https-port)  nginx_https_port=$2; shift 2 ;;
		--with-nginx-proxy-addr)  nginx_proxy_addr=$2; shift 2 ;;
		--with-apache)  install_apache=$2; shift 2 ;;
		--with-apache-public-port)  apache_publish_port=$2; shift 2 ;;
		--with-mysql)  install_mysql=$2; shift 2 ;;
		--with-mysql-host)  mysql_host=$2; shift 2 ;;
		--with-mysql-port)  mysql_port=$2; shift 2 ;;
		--with-mysql-user)  mysql_user=$2; shift 2 ;;
		--with-mysql-pass)  mysql_pass="$2"; shift 2 ;;
		--with-mysql-root-pass)  mysql_root_pass="$2"; shift 2 ;;
		--with-redis)  install_redis=$2; shift 2 ;;
		--with-redis-uri) redis_uri=$2; shift 2 ;;
		-- ) shift; break ;; 
		* ) print_log "解析参数错误!" "error" ; exit 1 ;;  
	esac
done
# 预处理变量
#prepareVar
# excute action
case "$action" in
    -h | --help | "help")
    	 usage; 
    ;;
    -v | --version|"version")
    	 print_log "$__ScriptName -- 版本 $__ScriptVersion" "info";
    ;;
	"installEnv")
		pretty_title "准备安装系统依赖软件"
		installEnv
	 ;;
	"clearEnv")
		pretty_title "准备卸载系统依赖软件"
		clearEnv
	 ;;
	 *)
	 	print_log "不支持此操作：$action" "error"
	 	usage
	 	exit 3
	 ;;
esac
exit 0
