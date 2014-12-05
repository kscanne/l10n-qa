#!/usr/bin/perl

my $datadir = '/home/kps/seal/l10n-qa';

use strict;
use warnings;
use utf8;
use HOP::Lexer 'string_lexer';
use Regexp::Common qw /URI/;
use Regexp::Common::Email::Address;
use Locale::PO;
use Encode qw(decode encode);

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my @input_tokens = (
[ 'URI',  qr/$RE{URI}/, \&text  ],
[ 'ESCAPED',   qr/\\[A-Za-z\x{22}]/, \&text   ], 
[ 'ESCAPED',   qr/\\\\/, \&text   ], 
[ 'EMAIL', qr/$RE{Email}{Address}/, \&text ], 
[ 'MARKUP', qr/<\/?[A-Za-z0-9]+>/, \&text   ], # <h3>, </font>
[ 'MARKUP', qr/<!--|-->/, \&text   ],
[ 'WILDCARD', qr/\*\.[A-Za-z]+(?:\.[A-Za-z]+)?/, \&text ],
[ 'ENTITY', qr/&(?:#[0-9]+|[A-Za-z]+);/, \&text  ],  # &nbsp;, &brandShortName;
[ 'OOVAR', qr/\%[a-z][a-z][a-z]+\%/, \&text ], #  %productname% %formatversion%
[ 'OOVAR', qr/\%[A-Z][A-Z][A-Z]+/, \&text ], #  %PRODUCTNAME, etc. 
[ 'CVAR', qr/\%(?:key|fire|dir|value|prev)/, \&text ], #  aspell
[ 'CVAR', qr/%-?[0-9](?:[ldu]|l[dx])/, \&text ], #  %3d
[ 'CVAR', qr/%\.\*s/, \&text ], #  %3d
[ 'CVAR', qr/%(?:[0-9a-z%]|ld|\.[0-9]+[fos])/, \&text ], # %1,%s,%ld
[ 'MOZVAR', qr/\${[A-Za-z_-]+}/, \&text ], # ${BrandShortName}
[ 'MOZVAR', qr/\$\(\^?[A-Za-z]+\)/, \&text ],  # $(^NameDA) 
[ 'KDEVAR', qr/%{[A-Za-z]+}/, \&text ],  #   %{dest}
[ 'MOZVAR', qr/%[0-9]\$[A-Za-z]/, \&text ],  # %1$S 
[ 'OOVAR', qr/\(\$[A-Za-z]+[0-9]?\)/, \&text ],  # ($Arg1)
[ 'OOVAR', qr/{&[A-Za-z0-9]+}/, \&text ],  # {&MSSansBold8} 
[ 'MOZVAR', qr/\$[A-Za-z]+\$/, \&text  ],  #  $ProductName$ 
[ 'ENVVAR', qr/\$[A-Z]+/, \&text  ],  #  $JAVAC 
#[ 'MODNUMBER', qr/[#$][0-9]+/, \&text  ],  #  #1, #2, $100
[ 'OPERATOR', qr/(?:!=|==)/, \&text   ],
[ 'SPECIAL', qr/(?:(?:ISO|iso)-?8859-?[0-9]+|(?:UTF|utf)-?8|DVD+RW?|DVD-RW|C\+\+|GTK\+|I\/O|OS\/2|S\/MIME|TCP\/IP|N\/A|OpenOffice\.org|X\.org|X11)/, \&text ],
# a hack to get words... input is utf8 but read as "bytes" by Perl
# word chars in Latin-1 range encode as A+tilde and then another char 
[ 'WORD',   qr/[A-Za-z\x{80}-\x{FF}'-]+/, \&text  ],
[ 'SPACE',  qr/\s*/,    sub{}    ],
[ 'OTHER',  qr/./, \&text        ],
);

sub text {
	my ( $label, $value ) = @_;
	return [ $label, $value ];
}


sub tokenize
{
	my ($str) = @_;
	my @ans;

	$str =~ s/  */ /g;    # for efficiency

	my $lexer = string_lexer($str, @input_tokens);
	
	while ( my $tok = $lexer->()) {
		my ($label, $val) = @$tok;
		push @ans, $val;
	}

	return @ans;
}

# almost the same code as buildTA
sub massage
{
        my ( $msg ) = @_;
        $msg =~ s/^"//;
        $msg =~ s/"$//;
        $msg =~ s/&([A-Za-z]+;)/\x{AC}$1/g;   # "escape" legit "&"'s (entities)
        $msg =~ s/{&([A-Za-z0-9]+})/{\x{AC}$1/g;   # OOo
        my $accel = ($msg =~ s/&([A-Za-z0-9])/$1/);    # accelerator key
        $msg =~ s/{\x{AC}([A-Za-z0-9]+})/{&$1/g;
        $msg =~ s/\x{AC}([A-Za-z]+;)/&$1/g;   # undo "escape"
        return  ($msg,$accel);
}


sub my_warn
{
return 1;
}

if (@ARGV == 0) {
	die "Usage: $0 POFILES\n";
}

my %pastexp;

open(DB, "<:utf8", "$datadir/copied.txt") or die "Níorbh fhéidir copied.txt a oscailt: $!\n";
while (<DB>) {
	chomp;
	(my $prob, my $tok) = /^([^ ]+) (.*)$/;
	$pastexp{$tok} = $prob;
}
close DB;

while ($ARGV = shift @ARGV) {
	my $ooo = ($ARGV =~ /OOo/);
	my $aref;
	{
		local $SIG{__WARN__} = 'my_warn';
		$aref = Locale::PO->load_file_asarray($ARGV);
	}
	shift(@$aref);  # PO header
	foreach my $msg (@$aref) {
		my %counts=();
		my $id = decode("utf8", $msg->msgid());
		my $str = decode("utf8", $msg->msgstr());
		if (defined($id) && defined($str)) {
			my $id_accel;
			my $str_accel;
			my $accel_key = '&';
			($id,$id_accel) = massage($id);
			$id =~ s/^_: .*\\n//;
			($str,$str_accel) = massage($str);
			if ($ooo) {
				$id_accel = ($id =~ s/~([A-Za-z0-9])/$1/);
				$str_accel = ($str =~ s/~([A-Za-z0-9])/$1/);
				$accel_key = '~'
			}
			if ($str and $id and $id !~ /^_n:/) {  # KDE plurals won't have matching counts of course - could do a *5 maybe!
				if ($id_accel and !$str_accel) {
					print "\n\nAicearra $accel_key ar iarraidh ó msgstr\n";
					print "Msgid=$id\n";
					print "Msgstr=$str\n";
					print "\n\n";
				}
				if (!$id_accel and $str_accel) {
					print "\n\nAicearra gan gá $accel_key in msgstr\n";
					print "Msgid=$id\n";
					print "Msgstr=$str\n";
					print "\n\n";
				}
				foreach my $s (tokenize($id)) {
					$counts{$s}++;
				}
				foreach my $t (tokenize($str)) {
					if (exists($counts{$t})) {
						$counts{$t}--;
					}
				}
				foreach my $cand (keys %counts) {
					if ($counts{$cand} == 0) {
						1;
					}
					else {
						if (exists($pastexp{$cand})) {
							print "\n\nNí hionann líon an chomhartha $cand sa msgid agus sa msgstr\n";
							print "Msgid=$id\n";
							print "Msgstr=$str\n";
							print "Cóipeáladh an comhartha seo le dóchúlacht $pastexp{$cand} in aistriúcháin roimhe seo\n";
							print "\n\n";
						}
					}
				}
			}  # both non-empty
		} # both defined
	} # loop over PO entries
}  # loop over PO files

exit 0;
