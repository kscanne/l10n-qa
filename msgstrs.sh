#!/bin/bash
INSTALLDIR=${HOME}/seal/l10n-qa
# this dumps msgstrs; leaves blank lines between msgstrs and for all 
# missing translations; leave these in and client programs will do
# what they need to - e.g. for grammar checking, insert a ".", etc.
cat $@ | sed '1,/^$/d' | egrep -v '^#' | sed '/^msgctxt/,/^msgstr/{/^msgstr/!d}' | sed '/^msgid/,/^msgstr/{/^msgstr/!d}' | sed 's/^msgstr "/"/' | sed 's/^msgstr\[[0-9]\] "/"/' | sed 's/^"//' | sed 's/"$//' | perl ${INSTALLDIR}/de-entify.pl | sed 's/[&~]//'
