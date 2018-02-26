#!/bin/bash

######################################
# 
# 脚本名称: publish_doc.sh
#
# 描述：
#       生成并部署文档
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
__ScriptVersion='publish-doc-20180224171815'
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

cxl_log "生成文档"
cd doc && make html 
cd ..
scp -r doc/_build/html/* root@doc29:/var/www/html/envctl/doc/ 
ssh doc29 "chmod 777 /var/www/html/envctl -R"