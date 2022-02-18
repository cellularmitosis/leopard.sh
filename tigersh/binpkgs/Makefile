FIXME this isn't working

BINPKGS = $( shell ls *.tar.gz | sed 's/$/.md5/' )

md5sums.txt: $(BINPKGS)
	cat *.md5 > manifest.md5

%.md5 : %.tar.gz
	echo -n "$< " > $@
	md5 -q $< >> $@
