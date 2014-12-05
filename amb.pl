#!/usr/bin/perl

my $datadir = '/home/kps/seal/l10n-qa';

use strict;
use warnings;
use utf8;
use Locale::PO;
use Encode qw(decode encode);

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

if (@ARGV == 0) {
	die "Usage: $0 POFILES\n";
}

my @rules;  # array of hash refs

open (KNOWNAMBS, "<:utf8", "$datadir/amb.txt") or die "Níorbh fhéidir amb.txt a oscailt: $!\n";

while(<KNOWNAMBS>) {
	unless (/^#/) {
		chomp;
		(my $origid, my $expl) = /^([^\t]+)\t+(.*)$/;
		my $id = $origid;
		if ($id =~ /^\^/) {
			$origid =~ s/^\^//;
			$id =~ s/^\^/^"/;
			$id =~ s/$/"\$/;
		}
		else {
			$id =~ s/^/\\W/;
			$id =~ s/$/\\W/;
		}
		push @rules, {
			'orig' => $origid,
			'expl' => $expl,
			'pattern' => qr/$id/i,
		};
	}
}

sub my_warn
{
return 1;
}

while ($ARGV = shift @ARGV) {
	my $aref;
{
	local $SIG{__WARN__} = 'my_warn';
	$aref = Locale::PO->load_file_asarray($ARGV);
}
	print "Comhad PO $ARGV á sheiceáil...\n"
	foreach my $msg (@$aref) {
		my $id = decode("utf8", $msg->msgid());
		my $str = decode("utf8", $msg->msgstr());
		if (defined($id) && defined($str)) {
			if ($str and $id) {
				$id =~ s/^"_: .*\\n//;
				foreach my $rule (@rules) {
					my $searchid = $id;
					$searchid =~ s/[~&]//g;
					$searchid =~ s/\\n//g;
					$searchid =~ s/%[0-9a-zA-Z]//g;
					$searchid =~ s/: *//g;
					$searchid =~ s/\.\.\.//g;
					my $idpatt = $rule->{'pattern'};
					if ($searchid =~ m/$idpatt/) {
						my $explanation = $rule->{'expl'};
						print "Aimsíodh téarma déchiallach \"$rule->{'orig'}\" i msgid\n\tmsgid=$id\n\tmsgstr=$str\n\tMíniú: $rule->{'expl'}\"\n\n";
					}
				}
			}
		}
	}
}

exit 0;
