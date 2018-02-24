使用方法
==========

远程下载版本
-----------------

* mkdir bin && cd bin && curl -LO http://10.0.0.29/envctl/envctl.sh

查看版本及使用方法
------------------------------------

* ./envctl.sh 或 ./envctl.sh help

安装软件
----------------

安装mysql
^^^^^^^^^^^^^^^

* ./envctl.sh install mysql 'mysqlrootpassword' 
* ./envctl.sh install mysql 不带第三个参数，缺省密码是C1oudP8x&2017


安装redis
^^^^^^^^^^^^^^^
* ./envctl.sh install redis

安装nginx
^^^^^^^^^^^^^^^
* ./envctl.sh install nginx

安装apache
^^^^^^^^^^^^^^^
* ./envctl.sh install apache

安装php
^^^^^^^^^^^^^^^
* ./envctl.sh install php

安装所有
^^^^^^^^^^^^^^^

* ./envctl.sh install all 顺序安装以上软件

卸载软件
------------------  

卸载mysql
^^^^^^^^^^^^^^^
* ./envctl.sh remove mysql

卸载redis
^^^^^^^^^^^^^^^
* ./envctl.sh remove redis

卸载nginx
^^^^^^^^^^^^^^^
* ./envctl.sh remove nginx

卸载apache
^^^^^^^^^^^^^^^
* ./envctl.sh remove apache


卸载php
^^^^^^^^^^^^^^^
* ./envctl.sh remove php

卸载所有
^^^^^^^^^^^^^^^  
* ./envctl.sh remove all 顺序卸载以上软件