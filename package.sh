#!/bin/bash

######################################
# 
# 脚本名称: package.sh
#
# 描述：
#       打包部署软件
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
#   curl -LO http://10.0.0.29/envctl/envctl.sh && ./envctl.sh remove mysql
#
######################################

# 声明脚本变量
__ScriptFullName=$(readlink -f $0)  
__ScriptName=$(basename $__ScriptFullName)
__ScriptDir=$(dirname $__ScriptFullName)
__ScriptVersion="envctl-2018.02.11" 
__CurrentUser=$(whoami)
__LogPath=$__ScriptDir/log/package/
__LogFile=$__LogPath`date +'%Y%m%d'`.log

# 创建目录
if [ ! -d "$__ScriptDir/log/package/" ]; then
    mkdir "$__ScriptDir/log/package/" -p
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

is_ubuntu 16.04 && status=0 || status=1
if [  "$status" -gt 0 ]; then cxl_log "当前系统非ubuntu 16.04，此安装程序只在ubuntu16.04上做过测试" "error"; return 2; fi

cxl_log "创建目录/var/www/html/envctl"
ssh doc29 "mkdir /var/www/html/envctl/doc -p"
cxl_log "设置版本"
version="envctl-"`date +'%Y%m%d%H%M%S'`
sed -ri "s#(__ScriptVersion=).*#\1'$version'#" envctl.sh
sed -ri "s#(__ScriptVersion=).*#\1'$version'#" config_ebss.sh
sed -i "s/<%NEWVERSION%>/$version/" doc/release.rst 
cxl_log "生成文档"
cd doc && make html 
cd ..
cxl_log "生成ebss配置包"
tar zcvf config_ebss.tar config_ebss.sh crt/ res/ 
cxl_log "远程拷贝文件"
scp envctl.sh root@doc29:/var/www/html/envctl/
scp config_ebss.tar root@doc29:/var/www/html/envctl/
rm config_ebss.tar -f
scp -r doc/_build/html/* root@doc29:/var/www/html/envctl/doc/  
ssh doc29 "chmod 777 /var/www/html/envctl -R"