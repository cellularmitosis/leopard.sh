run:
	cd leopardsh/deps && make dependencies.png
	cd tigersh/deps && make dependencies.png
	cd leopardsh/build-times && make
	cd tigersh/build-times && make

.PHONY: run
