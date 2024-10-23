<?php

$dbdir = $_SERVER['DOCUMENT_ROOT'].'/private';
if (!is_dir($dbdir)) {
  mkdir($dbdir, 0777, true);
}
$dbpath = "$dbdir/db.sqlite3";

define('DB', new PDO("sqlite:$dbpath"));