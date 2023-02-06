all: md5s dependency-graphs

md5s:
	$(shell printf "The MD5 sum of leopard.sh is:\n\n    " > md5)
	$(shell md5 -q leopard.sh >> md5)
	$(shell printf "\nThe MD5 sum of tiger.sh is:\n\n    " >> md5)
	$(shell md5 -q tiger.sh >> md5)
	$(shell printf "\nThe MD5 sum of tigersh-deps-0.1-tiger.g3.tar.gz is:\n\n    " >> md5)
	$(shell md5 -q tigersh/binpkgs/tigersh-deps-0.1.tiger.g3.tar.gz >> md5)
	cd binpkgs && make
	cd dist && make
	cd dist/orig && make
	cd leopardsh/scripts && make
	cd tigersh/scripts && make
	cd leopardsh/config.cache && make
	cd tigersh/config.cache && make
	utils/generate-manifest.sh

dependency-graphs:
	cd leopardsh/deps && make dependencies.png
	cd tigersh/deps && make dependencies.png

stats:
	cd stats && make

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

.PHONY: all md5s dependency-graphs stats clean
