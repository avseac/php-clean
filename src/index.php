<?php
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/live-reload.php';
// require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/database-sqlite.php';
?>


<!DOCTYPE html>
<html lang="en">
<head>
  <title>Index</title>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
  <?= date(format: 'm/d/Y H:i:s', timestamp: time()); ?>
</body>
</html>