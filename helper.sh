######################################
# 
# 脚本名称: helper.sh
#
# 功能:
#     功能辅助类
#  
# 注意事项：
#     使用source包含         
# 
# 作者: chenxuelin@emicnet.com
#    
######################################


# ----------------------------
# 结束运行函数
# ----------------------------
terminate(){
    local msg="控制程序已终止"
    print_log "$msg" "info" 
    exit 1
}

# ----------------------------
# 检查运行环境函数
# ----------------------------
checkEnv(){
	local status=1
	command -v cxl_log>/dev/null && status=0 || status=1
	if [  "$status" -gt 0 ]; then print_log "本程序依赖于cxl_log" "error"; return 2; fi
	command -v cxl_system>/dev/null && status=0 || status=1
	if [  "$status" -gt 0 ]; then print_log "本程序依赖于cxl_system" "error"; return 2; fi
	command -v cxl_string>/dev/null && status=0 || status=1
	if [  "$status" -gt 0 ]; then print_log "本程序依赖于cxl_string" "error"; return 2; fi
	command -v cxl_print>/dev/null && status=0 || status=1
	if [  "$status" -gt 0 ]; then print_log "本程序依赖于cxl_print" "error"; return 2; fi
	is_ubuntu 16.04 && status=0 || status=1
	if [  "$status" -gt 0 ]; then print_log "当前系统非ubuntu 16.04，此安装程序只在ubuntu16.04上做过测试" "error"; return 2; fi
	if [  "$__CurrentUser" != "root" ]; then print_log "需要root用户，当前用户是:$_current_user" "error"; return 2; fi
    return $status
}
# ----------------------------
# 安装系统环境
# ----------------------------
installEnv(){
	local status=0
	print_log "正在安装系统软件" "info"
	
	print_log "准备安装ubuntu静默安装工具debconf-utils" "info"
	check_and_install_soft debconf-utils && status=0 || status=1
	if [ $status -gt 0 ]; then
		print_log "安装debconf-utils失败,退出程序，请手工安装debconf-utils，再次运行此脚本" "error"
		exit 4
	else
		print_log "设置静默安装参数" info
		# 修改mysql的密码	
		cp "$__ScriptDir/debparam.conf" "$__ScriptDir/debparam_bak.conf" 
		local tmp_mysql_root_pass=${mysql_root_pass//&/\\&}
		sed -i "s/MYSQLROOTPASS/$tmp_mysql_root_pass/g" "$__ScriptDir/debparam_bak.conf" 
		debconf-set-selections "$__ScriptDir/debparam_bak.conf"
		rm "$__ScriptDir/debparam_bak.conf"
	fi
	print_log "安装debconf-utils已完成" info
	
	print_log "准备安装进程管理工具supervisor" "info"
	check_and_install_soft supervisor && status=0 || status=1
	print_log "安装supervisor已完成" info
	
	print_log "准备安装json处理命令jq" "info"
	check_and_install_soft jq && status=0 || status=1
	print_log "安装jq已完成" info
	
	print_log "准备安装转码工具lame" "info"
	check_and_install_soft lame && status=0 || status=1
	print_log "安装lame已完成" info

	# 安装mysql
	print_log "准备安装mysql" "info"
	if [ $install_mysql -gt 0 ]; then	
		check_and_install_soft mysql-server
		apt install libmysqlclient-dev -y
		print_log "安装mysql已完成" info
	else
		print_log "未配置安装mysql，跳过安装" warn
	fi
	
	# 安装nginx
	print_log "准备安装nginx" "info"
	if [ $install_nginx -gt 0 ]; then	
		check_and_install_soft nginx
		print_log "安装nginx已完成" info
	else
		print_log "未配置安装nginx，跳过安装" warn
	fi
	
	# 安装redis
	print_log "准备安装redis" "info"
	if [ $install_redis -gt 0 ]; then	
		check_and_install_soft redis-server
		print_log "安装redis已完成" info
	else
		print_log "未配置安装redis，跳过安装" warn
	fi
	
	# 安装apache
	print_log "准备安装apache" "info"
	if [ $install_apache -gt 0 ]; then	
		check_and_install_soft apache2
		print_log "安装apache已完成" info
		print_log "停止apache模块mpm_event,mpm_prefork,打开mpm_worker,rewrite,proxy_fcgi" info
		a2dismod mpm_event
		a2dismod mpm_prefork
		a2enmod mpm_worker rewrite proxy_fcgi
		# 安装php7.0
		print_log "准备安装php7.0" "info"
		check_and_install_soft php7.0 && status=0 || status=1
		if [ $status != 0 ]; then
			print_log "php7.0安装失败，跳过安装依赖库" "error"
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
			#check_and_install_soft libapache2-mod-fastcgi
			print_log "停止apache模块php7.0，启用php7.0-fpm配置文件" info
			a2dismod php7.0
			a2enconf php7.0-fpm
		fi
	else
		print_log "未配置安装apache，跳过安装" warn
	fi
}

# ----------------------------
# 删除环境
# ----------------------------
clearEnv(){
	local status=0
	print_log "正在卸载系统软件" "info"
	
	check_and_remove_soft supervisor && status=0 || status=1
	print_log "卸载supervisor已完成" "info"
	if [ $status = 0 ]; then print_log "删除supervisor配置文件" "warn" ; rm /etc/supervisor -rf; fi
	
	print_log "准备卸载php7.0相关软件" "info"
	# 先删除依赖mysql，apache的包，mcrypt和libmcrypt-dev是系统包，不删除
	check_and_remove_soft libapache2-mod-php7.0
	check_and_remove_soft libapache2-mod-fastcgi
	check_and_remove_soft php7.0-mysql
	check_and_remove_soft php-common && status=0 || status=1
	print_log "卸载php7.0已完成" "info"
	if [ $status = 0 ]; then print_log "删除php7.0配置文件" "warn" ; rm /etc/php -rf; fi

	check_and_remove_soft apache2 && status=0 || status=1
	if [ $status = 0 ]; then print_log "删除apache2配置文件" "warn" ; rm /etc/apache2 -rf; fi
	print_log "卸载apache2已完成" "info"
	
	check_and_remove_soft nginx-common && status=0 || status=1
	if [ $status = 0 ]; then print_log "删除nginx配置文件" "warn" ; rm /etc/nginx -rf; fi
	print_log "卸载nginx已完成" "info"
	
	check_and_remove_soft mysql-common && status=0 || status=1	
	if [ $status = 0 ]; then		
		print_log "删除mysql配置文件和库文件" "warn"
		# 删除配置文件
		rm /etc/mysql -rf 
		# 删除库文件
		rm /var/lib/mysql -rf
	fi
	print_log "卸载mysql已完成" "info"
	
	check_and_remove_soft redis-server && status=0 || status=1
	if [ $status = 0 ]; then print_log "删除redis配置文件" "info" ; rm /etc/redis -rf; fi
	print_log "卸载redis-server已完成" "info"	
}
# ----------------------------
# 预处理特殊字符
# ----------------------------
prepareVar(){
	print_log "预处理数据" info
	#mysql_root_pass=${mysql_root_pass//&/\\&}
	#mysql_pass=${mysql_pass//&/\\&}
}
