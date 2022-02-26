all: md5s dependency-graphs

md5s:
	$(shell echo "The MD5 sum of leopard.sh is:" > md5)
	$(shell echo >> md5)
	$(shell md5 -q leopard.sh >> md5)
	$(shell echo >> md5)
	$(shell echo "The MD5 sum of tiger.sh is:" >> md5)
	$(shell echo >> md5)
	$(shell md5 -q tiger.sh >> md5)
	$(shell echo >> md5)
	$(shell echo "The MD5 sum of tigersh-deps-0.1-tiger.g3 is:" >> md5)
	$(shell echo >> md5)
	$(shell md5 -q tigersh/binpkgs/tigersh-deps-0.1.tiger.g3.tar.gz >> md5)
	cd leopardsh/binpkgs && make
	cd tigersh/binpkgs && make


dependency-graphs:
	cd leopardsh/deps && make dependencies.png
	cd tigersh/deps && make dependencies.png

stats:
	cd stats && make

clean:
	cd leopardsh/binpkgs && make clean
	cd tigersh/binpkgs && make clean
	cd leopardsh/deps && make clean
	cd tigersh/deps && make clean
	cd stats && make clean

.PHONY: all md5s dependency-graphs stats clean
