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

my @rules;   # array of hash refs

open (DEPRECATED, "<:utf8", "$datadir/deprecated.txt") or die "Níorbh fhéidir deprecated.txt a oscailt: $!\n";

while(<DEPRECATED>) {
	unless (/^#/) {
		chomp;
		my ($eng,$dep,$pref,$enpatt,$gapatt) = m/^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/;
		$eng =~ s/_/ /g;
		$dep =~ s/_/ /g;
		$pref =~ s/_/ /g;
		push @rules, {
				'english' => $eng,
				'deprecated' => $dep,
				'preferred' => $pref,
				'english_pattern' => qr/$enpatt/i,
				'irish_pattern' => qr/$gapatt/i,
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
	print "Comhad PO $ARGV á sheiceáil...\n";
	foreach my $msg (@$aref) {
		my $id = decode("utf8", $msg->msgid());
		my $str = decode("utf8", $msg->msgstr());
		if (defined($id) && defined($str)) {
			if ($str and $id) {
				$id =~ s/^"_: .*\\n//;
				foreach my $rule (@rules) {
					my $searchid = $id;
					my $searchstr = $str;
					$searchid =~ s/[~&]//g;
					$searchstr =~ s/[~&]//g;
					my $en = $rule->{'english_pattern'};
					my $ga = $rule->{'irish_pattern'};
					if ($searchid =~ m/$en/ and $searchstr =~ m/$ga/) {
						print "Aimsíodh téarma i léig \"$rule->{'deprecated'}\" mar aistriúchán ar \"$rule->{'english'}\"\n\tmsgid=$id\n\tmsgstr=$str\n\tBa chóir duit \"$rule->{'preferred'}\" a úsáid ina ionad\n\n";
					}
				}
			}
		}
	}
}

exit 0;
