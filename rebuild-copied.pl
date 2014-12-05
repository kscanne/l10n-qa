#!/usr/bin/perl

# use this script periodically to create "copied.txt"
# sort the output of this script on the first column and
# keep >= 0.5
#   Usage: % perl copych-survey.pl  | ...   (see makefile)


use strict;
use warnings;
use utf8;
use HOP::Lexer 'string_lexer';
use Regexp::Common qw /URI/;
use Regexp::Common::Email::Address;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my @files = (
'abiword-b',
'amo-obair-b',
'aspell-b',
'audacity-b',
'bash-b',
'batchelor-b',
'bfd-b',
'bibshelf-b',
'binutils-b',
'biobla-b',
'bison-b',
'bison-runtime-b',
'bluez-pin-b',
'bugzilla-comps-b',
'calendar-trunk-b',
'cflow-b',
'clisp-b',
'console-data-b',
'coreutils-b',
'cpio-b',
'darkstat-b',
'debconf-b',
'debian-installer-aceathair-b',
'debian-installer-acuig-b',
'debian-installer-ado-b',
'debian-installer-ahaon-b',
'debian-installer-atri-b',
'dialog-b',
'diffutils-b',
'doodle-b',
'eject-b',
'enscript-b',
'error-b',
'ffinstaller-b',
'ffsnippets-b',
'findutils-b',
'firefox-trunk-b',
'flex-b',
'freeciv-b',
'gawk-b',
'gcal-b',
'gettext-examples-b',
'gettext-runtime-b',
'gettext-tools-b',
'gip-b',
'glunarclock-b',
'gnulib-b',
'gpe-timesheet-b',
'gpe-today-b',
'gprof-b',
'gramadoir-b',
'grep-b',
'gsasl-b',
'gss-b',
'gtick-b',
'gtkspell-b',
'gucharmap-b',
'hello-b',
'herrie-b',
'idutils-b',
'impost-b',
'indent-b',
'iso_15924-b',
'iso_3166-b',
'iso_639-b',
'joomla-b',
'kde-compend-b',
'keytouch-b',
'keytouch-editor-b',
'keytouch-keyboard-bin-b',
'latrine-b',
'ld-b',
'leafpad-b',
'libc-b',
'libextractor-b',
'libgpewidget-b',
'libgsasl-b',
'libiconv-b',
'linux-pam-b',
'm4-b',
'make-b',
'menu_po-sections-b',
'moodle-trunk-b',
'mutt-b',
'nano-b',
'newt-b',
'nsis-b',
'nsis-ui-b',
'OOo-b',
'opcodes-b',
'poedit-b',
'popt-b',
'popularity-b',
'recode-b',
'rpm-b',
'sed-b',
'shared-mime-info-b',
'sharutils-b',
'stardict-b',
'system-tools-backends-b',
'tar-b',
'tasksel-b',
'tasksel-debian-b',
'tasksel-tasks-b',
'tbinstaller-b',
'tbird-trunk-b',
'tecstio-b',
'texinfo-b',
'tp-robot-b',
'tshwanelex-b',
'tuxpaint-b',
'vim-b',
'vorbis-tools-b',
'wdiff-b',
'wget-b',
'win-loader-b',
'xpad-b',
'yudit-b',
);

# kill &,~ in PO, but not entity!    fix buildTA too?

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
[ 'SPECIAL', qr/(?:(?:ISO|iso)-?8859-?[0-9]+|(?:UTF|utf)-?8|DVD+RW?|DVD-RW|C\+\+|GTK\+|I\/O|OS\/2|S\/MIME|TCP\/IP|N\/A|OpenOffice\.org|X\.org)/, \&text ],
# a hack to get words... input is utf8 but read as "bytes" by Perl
# # word chars in Latin-1 range encode as A+tilde and then another char 
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

my %good;
my %total;

foreach my $bearla (@files) {
	$bearla =~ s/^/\/home\/kps\/gaeilge\/diolaim\/comp\//;
	my $gaeilge = $bearla;
	$gaeilge =~ s/-b$//;
	open(BEARLA, "<:utf8", "$bearla") or die "Níorbh fhéidir $bearla a oscailt: $!\n";
	open(GAEILGE, "<:utf8", "$gaeilge") or die "Níorbh fhéidir $gaeilge a oscailt: $!\n";
	while (<BEARLA>) {
		my %counts=();
		chomp;
		my $b = $_;
		$b =~ s/^[0-9]+: //;
		chomp(my $g = <GAEILGE>);
		$g =~ s/^[0-9]+: //;
		foreach my $s (tokenize($b)) {
			$counts{$s}++;
		}
		foreach my $t (tokenize($g)) {
			if (exists($counts{$t})) {
				$counts{$t}--;
			}
		}
		foreach my $cand (keys %counts) {
			$total{$cand}++;
			if ($counts{$cand} == 0) {
				$good{$cand}++;
			}
			else {
				$good{$cand}=0 unless exists($good{$cand});
			}
		}
	}
	close BEARLA;
	close GAEILGE;
}

foreach my $eng (keys %total) {
	my $frac = $good{$eng}/$total{$eng};
	print "$frac $eng\n";
}
