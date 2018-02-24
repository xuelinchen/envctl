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
    echo "<div>";
    echo "<p><a href='/$dir/doc'>$dir文档</a></p>";
    echo "</div>";
  }
} catch (Exception $e) {
  echo $e->getMessage();
}
//$dirs = scandir('/tmp');
//var_dump($dirs);
?>
</body>
</html>