<?php

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$file = __DIR__ . '/../' . ltrim($path, '/');

if ($path !== '/' && is_file($file)) {
	return false;
}

if ($path !== '/' && is_dir($file) && is_file($file . '/index.php')) {
	require $file . '/index.php';
	return true;
}

require __DIR__ . '/../index.php';
