all: md5s
.PHONY: all

md5s: binpkgs-md5s dist-md5s leopardsh-md5s tigersh-md5s md5
	utils/generate-manifest.sh
.PHONY: md5s

md5: leopardsh/leopard.sh tigersh/tiger.sh binpkgs/tigersh-deps-0.1.tiger.g3.tar.gz
	$(shell printf "The MD5 sum of leopard.sh is:\n\n    " > md5)
	$(shell md5 -q leopardsh/leopard.sh >> md5)
	$(shell printf "\nThe MD5 sum of tiger.sh is:\n\n    " >> md5)
	$(shell md5 -q tigersh/tiger.sh >> md5)
	$(shell printf "\nThe MD5 sum of tigersh-deps-0.1-tiger.g3.tar.gz is:\n\n    " >> md5)
	$(shell md5 -q binpkgs/tigersh-deps-0.1.tiger.g3.tar.gz >> md5)

binpkgs-md5s:
	cd binpkgs && make
.PHONY: binpkgs-md5s

dist-md5s:
	cd dist && make
	cd dist/orig && make
.PHONY: dist-md5s

leopardsh-md5s:
	cd leopardsh && make
	cd leopardsh/scripts && make
	cd leopardsh/scripts/wip && make
	cd leopardsh/config.cache && make
.PHONY: leopardsh-md5s

tigersh-md5s:
	cd tigersh && make
	cd tigersh/scripts && make
	cd tigersh/scripts/wip && make
	cd tigersh/config.cache && make
.PHONY: tigersh-md5s

dependency-graphs:
	cd leopardsh/deps && make dependencies.png
	cd tigersh/deps && make dependencies.png
.PHONY: dependency-graphs

stats:
	cd stats && make
.PHONY: stats

clean:
	cd binpkgs && make clean
	cd dist && make clean
	cd dist/orig && make clean
	cd leopardsh/scripts && make clean
	cd tigersh/scripts && make clean
	cd leopardsh/config.cache && make clean
	cd tigersh/config.cache && make clean
	rm -f md5s.manifest md5s.manifest.gz
	cd leopardsh/deps && make clean
	cd tigersh/deps && make clean
	cd stats && make clean
.PHONY: clean
