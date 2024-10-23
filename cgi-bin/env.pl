#!/usr/bin/perl -w
use strict;
use warnings;


print "Content-type: text/plain\n\n";
foreach my $key (keys %ENV) {
    print "$key --> $ENV{$key}\n";
}