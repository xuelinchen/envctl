使用方法
==========

远程下载版本
-----------------

* mkdir bin && cd bin && curl -O http://10.0.0.29/envctl/config_ebss.tar && tar -zxvf config_ebss.tar



查看版本及使用方法
------------------------------------

* ./config_ebss.sh 或 ./config_ebss.sh help

配置
----------------

配置mysql
^^^^^^^^^^^^^^^

* ./config_ebss.sh mysql '123456' 如果为空缺省root密码是C1oudP8x&2017


配置redis
^^^^^^^^^^^^^^^
* ./config_ebss.sh redis

配置nginx
^^^^^^^^^^^^^^^
* ./config_ebss.sh nginx '' '127.0.0.1:1065'

配置apache
^^^^^^^^^^^^^^^
* ./config_ebss.sh apache

配置php
^^^^^^^^^^^^^^^
* ./config_ebss.sh php

配置所有
^^^^^^^^^^^^^^^

* ./config_ebss.sh all 顺序配置以上软件

