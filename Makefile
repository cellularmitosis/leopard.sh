all: dependency-graphs build-time-stats

dependency-graphs:
	cd leopardsh/deps && make dependencies.png
	cd tigersh/deps && make dependencies.png

build-time-stats:
	cd stats && make

.PHONY: all dependency-graphs build-time-stats
