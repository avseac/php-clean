#!/usr/bin/perl

use DBI;
use strict;
use warnings;
use FindBin qw($Bin);

my $database = "logs/logs.sqlite3";
my $requiredInit = 0;
if (!-f $database) {
	$requiredInit = 1;
}

my $driver   = "SQLite";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

my %Months = (
	'Jan' => "01", 'Feb' => "02", 'Mar' => "03", 'Apr' => "04",
	'May' => "05", 'Jun' => "06", 'Jul' => "07", 'Aug' => "08",
	'Sep' => "09", 'Oct' => "10", 'Nov' => "11", 'Dec' => "12",
);




sub ExecuteInitQuery {
	my ($query) = @_;
	my $rv = $dbh->do($query);
	if($rv lt 0) {
		print $DBI::errstr;
	}
	return;
}



if ($requiredInit eq 1) {
	ExecuteInitQuery(qq(
		CREATE TABLE Access (
			`Id` INTEGER PRIMARY KEY AUTOINCREMENT,
			`Date` CHAR(10) NOT NULL,
			`Time` CHAR(8) NOT NULL,
			`Timezone` VARCHAR(5) NOT NULL DEFAULT '+0000',
			`Method` VARCHAR(6) NOT NULL,
			`StatusCode` INTEGER NOT NULL,
      `LoggedUser` TEXT,
			`Resource` TEXT NOT NULL,
			`ResourceSize` INTEGER DEFAULT NULL,
			`HTTPVersion` VARCHAR(10) NOT NULL DEFAULT '1.0',
			`Client` TEXT NOT NULL
		);
	));

  ExecuteInitQuery(qq(
    CREATE TABLE Error (
      `Id` INTEGER PRIMARY KEY AUTOINCREMENT,
      `Date` CHAR(10) NOT NULL,
      `Time` CHAR(8) NOT NULL,
      `Title` VARCHAR(255) DEFAULT NULL,
      `Lvl` VARCHAR(64) DEFAULT NULL,
      `Msg` TEXT NOT NULL
    );
  ));
}


sub ReadAccessLog {
  my $filename = './logs/access.log';

  $dbh->begin_work;
  my $stmt = $dbh->prepare(qq(
    INSERT INTO Access(`Date`, `Time`, `Timezone`, `Method`, `StatusCode`, `LoggedUser`, `Resource`, `ResourceSize`, `HTTPVersion`, `Client`)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ));

  open(my $fileHandler, '<:encoding(UTF-8)', $filename) or die($!);
  while (my $line = <$fileHandler>) {
    chomp $line;
    if (length($line) eq 0) { continue; }
    if( $line =~ /^(?<client>.*) - (?<user>[\w.\/<>?;:"'`!@#$%^&*()\[\]{}_+=|\\-]+) \[(?<date>\d+\/\w+\/\d+:\d+:\d+:\d+ ?[+-]?\d+)\] "(?<method>\w*) (?<path>.*)(?<httpversion> HTTP\/[\d.]+)" (?<httpcode>\d+)? (?<size>[\d-]+) "(?<referer>.*?)" "(?<agent>.*)"$/gsi) {
      my $date = $+{date};
      my $client = $+{client};
      my $user = $+{user};
      my $method = $+{method};
      my $path = $+{path};
      my $httpcode = $+{httpcode};
      my $httpversion = $+{httpversion};
      my $size = $+{size};
      my $referer = $+{referer};
      my $agent = $+{agent};

      if ($size eq "-") { $size = undef; }
      if ($referer eq "-") { $referer = undef; }
      if ($user eq "-") { $user = undef; }
      my @httpVersionSplit = split /\//, $httpversion;
      

      if ($date =~ /^(?<day>\d+)\/(?<month>\w+)\/(?<year>\d+):(?<hour>\d+):(?<minute>\d+):(?<second>\d+) (?<timezone>[+-]?\d+)$/gsi ) {
        my $year = $+{year};
        my $month = $+{month};
        my $day = $+{day};
        my $hour = $+{hour};
        my $minute = $+{minute};
        my $second = $+{second};
        my $timezone = $+{timezone};

        my $date = sprintf "%s-%s-%s", $year, $Months{$month}, $day;
        my $time = sprintf "%s:%s:%s", $hour, $minute, $second;

        $stmt->execute($date, $time, $timezone, uc($method), $httpcode, $user, $path, $size, $httpVersionSplit[1], $client);
      } else {
        print($line."\n");
      }
    }
  }
  $dbh->commit;
}

sub ReadErrorLog {
  my $filename = './logs/error.log';

  $dbh->begin_work;
  my $stmt = $dbh->prepare(qq(
    INSERT INTO Error(`Date`, `Time`, `Title`, `Lvl`, `Msg`)
    VALUES (?, ?, ?, ?, ?)
  ));

  open(my $fileHandler, '<:encoding(UTF-8)', $filename) or die($!);
  while (my $line = <$fileHandler>) {
    chomp $line;
    if (length($line) eq 0) { continue; }
    if( $line =~ /^\[(?<date>\w+ \w+ \d+ \d+:\d+:\d+\.\d+ \d+)\] \[(?<title>\w+):(?<lvl>\w+)\] \[(pid \d+:tid \d+)\] (?<msg>.*?)$/gsi) {
      my $date = $+{date};
      my $title = $+{title};
      my $lvl = $+{lvl};
      my $msg = $+{msg};


      if ($date =~ /^(?<weekday>\w+) (?<month>\w+) (?<day>\d+) (?<hour>\d+):(?<minute>\d+):(?<second>\d+)\.\d+ (?<year>\d+)$/gsi ) {
        my $year = $+{year};
        my $month = $+{month};
        my $weekday = $+{weekday};
        my $day = $+{day};
        my $hour = $+{hour};
        my $minute = $+{minute};
        my $second = $+{second};

        my $date = sprintf "%s-%s-%s", $year, $Months{$month}, $day;
        my $time = sprintf "%s:%s:%s", $hour, $minute, $second;

        $stmt->execute($date, $time, $title, $lvl, $msg);
      } else {
        print($line."\n");
      }
    }
  }
  $dbh->commit;
}

ReadAccessLog();
ReadErrorLog();

$dbh->disconnect();