<?php
const ReloadKey = "auto-reload";
function rhash($folder)
{
  $rdi = new RecursiveDirectoryIterator($folder);
  $rii = new RecursiveIteratorIterator($rdi);
  $files = [];
  foreach ($rii as $file) {
    if ($file->isDir()) {
      continue;
    }
    $files[] = hash_file("md5", $file->getPathname());
  }
  return $files;
}
;

if (isset($_GET[ReloadKey])) {

  set_time_limit(0);
  header('Cache-Control no-cache');
  header('Content-Type: text/event-stream');
  header('Connection: keep-alive');

  $hash = rhash($_SERVER["DOCUMENT_ROOT"]);

  while (true) {
    $time = time();
    usleep(200 * 1000);
    if ($hash != rhash($_SERVER["DOCUMENT_ROOT"])) {
      break;
    }
  }

  echo "data: reload\n\n";
  flush();
  exit();
}
?>

<script>
  const evtSource = new EventSource("?<?php echo ReloadKey ?>");

  evtSource.onmessage = (e) => {
    if (e.data == "reload") {
      window.location.reload()
    };
  };
</script>