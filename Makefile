all: dependency-graphs build-time-stats

dependency-graphs:
	cd leopardsh/deps && make dependencies.png
	cd tigersh/deps && make dependencies.png

build-time-stats:
	cd leopardsh/build-times && make
	cd tigersh/build-times && make

.PHONY: all dependency-graphs build-time-stats
