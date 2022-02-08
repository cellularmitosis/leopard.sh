show: dependencies.png
	open dependencies.png

dependencies.png: dependencies.dot
	dot -Tpng dependencies.dot > dependencies.png

clean:
	rm -f dependencies.png

.PHONY: show clean
