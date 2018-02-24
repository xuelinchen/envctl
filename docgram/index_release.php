<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <title>EMICRELEASE</title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
</head>
<body>
<?php
echo "<h1> release列表 </h1>";
/* function getfiles($path){
	foreach(glob($path) as $afile){
		if(is_dir($afile)){ 
			getfiles($afile.'/*'); 
		}else { 
			echo $afile.'<br />'; 
		}
	}
}  */
$files = glob('*.tar');
function sort_by_mtime($file1,$file2) {
	$time1 = filemtime($file1);
	$time2 = filemtime($file2);
	if ($time1 == $time2) {
		return 0;
	}
	return ($time1 < $time2) ? 1 : -1;
}

usort($files,"sort_by_mtime");

foreach ($files as $afile){
	$mTime = date('Y-m-d H:i:s',filemtime($afile));
	echo "<p><a href='$afile'>$afile</a>---打包时间：$mTime</p>";
}
//简单的demo,列出当前目录下所有的文件
//getfiles(__DIR__);

?>
</body>
</html>