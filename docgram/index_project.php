<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <title>EMIC文档系统</title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
</head>
<body>
<?php
echo "<h1> 项目列表 </h1>";
try {
  $dirs = scandir('.');
  foreach($dirs as $dir){
    if('.' == $dir || '..' == $dir || is_file($dir)) continue;
    echo "<p>";
    echo "<a href='/$dir/doc'>".$dir."文档</a>";
    if(is_dir($dir.'/release')){
    	echo "-----<a href='/$dir/release'>".$dir."版本</a>";
    }
    echo "</p>";
  }
} catch (Exception $e) {
  echo $e->getMessage();
}
//$dirs = scandir('/tmp');
//var_dump($dirs);
?>
</body>
</html>