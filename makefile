
# don't run this if you're not kscanne
# since it depends on existing corpus of translated material
# to induce the list of untranslatables
copied.txt:
	perl rebuild-copied.pl | egrep '^(1|0\.[6-9])' | sort -k1,1 -r -n > $@

test:
	bash cpo.sh test.po > temptest.txt
	diff -u test.txt temptest.txt

clean:
	rm -f temptest.txt
