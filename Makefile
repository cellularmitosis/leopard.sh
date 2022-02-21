all: md5s dependency-graphs

md5s:
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
