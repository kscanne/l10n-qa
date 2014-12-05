#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use HTML::Entities;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

while (<STDIN>) {
	print decode_entities($_);
}

exit 0;
