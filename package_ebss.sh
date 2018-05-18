#!/bin/bash

######################################
# 
# 脚本名称: package_ebss.sh
#
# 描述：
#       配置业务支撑系统脚本
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
__ScriptVersion='package-ebss-20180224120819'
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
# 更新版本号
# ----------------------------
add_version(){
   result=`jq '.ebss' bin/snlocal.json| sed 's/"//g'` 
   if [ -z "$result" ]; then return 1; fi
   if [ "null" == "$result" ]; then return 1; fi 
   first=`echo $result|awk -F "." '{print $1}'`
   second=`echo $result|awk -F "." '{print $2}'`
   third=`echo $result|awk -F "." '{print $3}'`  
   if [ $third -gt 9998 ]; then
       if [ $second -gt 98 ]; then
           let first=$first+1
           second=0
           third=0
       else
           let second=$second+1
           third=0
       fi
   else
       let third=$third+1
   fi
   cliVer="$first.$second.$third"
   cmdLine="sed -i 's/\\(\"ebss\":\"\\).*/\\1$cliVer\"/g' bin/snlocal.json"
   #echo $cmdLine
   eval $cmdLine
   echo $cliVer
   #sed 's/\("cli":"\).*/\1$first.$second.$third"/g' snlocal.json
}

is_ubuntu 16.04 && status=0 || status=1
if [  "$status" -gt 0 ]; then cxl_log "当前系统非ubuntu 16.04，此安装程序只在ubuntu16.04上做过测试" "error"; return 2; fi

# 功能变量
packageDir='packageBss'

cxl_log "---------start package bss----------"

if [ ! -d "$packageDir" ]; then mkdir "$packageDir" -p; fi
cd $packageDir

cxl_log "checkout end from git"
if [ -d "ebss" ]; then
    chmod 777 ebss -R && cd ebss && git pull origin master
else
    git clone git@gitlab28:websrc/ebss.git && chmod 777 ebss -R && cd ebss
fi
cxl_log "生成新版本号"
version=`add_version`
if [ -z "$version" ]; then
    cxl_log "获取版本号失败"
    exit 1
fi

makeDate=`date +'%Y-%m-%d %H:%M:%S'`
sed -i "s/<%NEWVERSION%>/$version（$makeDate）/" doc/release.rst 
cxl_log "添加新版本号到版本库:$ver"
cp bin/snlocal.json public/sn.json -f
git add doc/release.rst 
git add bin/snlocal.json
git add public/sn.json
git commit -m 'add version by package'
git push origin master

#composer安装依赖
cxl_log "composer安装依赖"
chmod * -R
#if [ ! -d "thinkphp" ]; then mkdir thinkphp; fi
# 由于以root身份运行composer update脚本，屏蔽第三方脚本保证安全
#composer update --no-plugins --no-scripts
composer update
cxl_log "生成文档目录"
cd doc && make html 
cd ..
ssh doc29 "mkdir /var/www/html/ebss/doc -p"
scp -r doc/_build/html/* root@doc29:/var/www/html/ebss/doc/ 
cxl_log "建立打包目录"
cd ..
cxl_log "checkout front from git"
if [ -d "emicBss_front" ]; then
    cxl_log "删除目录emicBss_front"
    rm emicBss_front -rf
fi
git clone git@gitlab28:websrc/emicBss_front.git
if [ -d "emicBss_front/dist" ]; then
    cxl_log "拷贝前端程序到包目录"
    cp emicBss_front/dist/* ebss/public/ -rf
fi

cxl_log "打包后台安装包"
tarfilename="ebss-$version.tar"
tar -czvf $tarfilename ebss/
cxl_log "拷贝包到release目录"
ssh doc29 "mkdir /var/www/html/ebss/release -p"
scp $tarfilename  root@doc29:/var/www/html/ebss/release/ 
rm $tarfilename -f
cd ..
scp docgram/index_release.php  root@doc29:/var/www/html/ebss/release/index.php
cxl_log "*********end***********"
exit









