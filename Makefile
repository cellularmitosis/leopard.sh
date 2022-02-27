all: md5s dependency-graphs

md5s:
	$(shell printf "The MD5 sum of leopard.sh is:\n\n    " > md5)
	$(shell md5 -q leopard.sh >> md5)
	$(shell printf "\nThe MD5 sum of tiger.sh is:\n\n    " >> md5)
	$(shell md5 -q tiger.sh >> md5)
	$(shell printf "\nThe MD5 sum of tigersh-deps-0.1-tiger.g3 is:\n\n    " >> md5)
	$(shell md5 -q tigersh/binpkgs/tigersh-deps-0.1.tiger.g3.tar.gz >> md5)
	cd binpkgs && make
	cd dist && make

dependency-graphs:
	cd leopardsh/deps && make dependencies.png
	cd tigersh/deps && make dependencies.png

stats:
	cd stats && make

clean:
	cd binpkgs && make clean
	cd dist && make clean
	cd leopardsh/deps && make clean
	cd tigersh/deps && make clean
	cd stats && make clean

.PHONY: all md5s dependency-graphs stats clean
