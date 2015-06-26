<?php
$log_file = "../hook.log";

if (!preg_match('/^(149\.154\.167\.[12]?[0-9]{1,2})$/',$_SERVER['REMOTE_ADDR']))
        die("Nope.");

$tmp = file_get_contents('php://input');
$tmp = str_replace("\n","",$tmp);

if (json_decode($tmp))
        file_put_contents($log_file, $tmp."\n", FILE_APPEND | LOCK_EX);
else
        die("Not valid JSON.");
