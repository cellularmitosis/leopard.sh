#!/bin/bash

# tag a package.

if test -z "$1" ; then
    echo "Error: tag which pkgspec?" >&2
    echo "e.g. $(basename $0) gzip-1.11" >&2
    exit 1
fi

set -e

pkgspec=$1
shift 1

if test -z "$1" ; then
    echo "Error: apply which tag to $pkgspec?" >&2
    echo "e.g. $(basename $0) gzip-1.11 compression" >&2
    exit 1
fi

cd ~/leopard.sh

# thanks to https://stackoverflow.com/a/4749368
if grep --fixed-strings --line-regexp --quiet $pkgspec tigersh/packages.txt ; then
    in_tiger=1
fi
if grep --fixed-strings --line-regexp --quiet $pkgspec.ppc64 tigersh/packages.ppc64.txt ; then
    in_tiger64=1
fi
if grep --fixed-strings --line-regexp --quiet $pkgspec leopardsh/packages.txt ; then
    in_leopard=1
fi
if grep --fixed-strings --line-regexp --quiet $pkgspec.ppc64 leopardsh/packages.ppc64.txt ; then
    in_leopard64=1
fi

temp=$(mktemp)
while test -n "$1" ; do
    tag=$1
    shift 1
    if test -n "$in_tiger" ; then
        echo "tagging tiger/$pkgspec as $tag."
        echo $pkgspec >> tigersh/tags/$tag.txt
        cat tigersh/tags/$tag.txt | sort | uniq > $temp
        cat $temp > tigersh/tags/$tag.txt

        echo $tag >> tigersh/tags/tags.txt
        cat tigersh/tags/tags.txt | sort | uniq > $temp
        cat $temp > tigersh/tags/tags.txt
    fi
    if test -n "$in_tiger64" ; then
        echo "tagging tiger/$pkgspec.ppc64 as $tag."
        echo $pkgspec.ppc64 >> tigersh/tags/$tag.txt
        cat tigersh/tags/$tag.txt | sort | uniq > $temp
        cat $temp > tigersh/tags/$tag.txt

        echo $tag >> tigersh/tags/tags.txt
        cat tigersh/tags/tags.txt | sort | uniq > $temp
        cat $temp > tigersh/tags/tags.txt
    fi
    if test -n "$in_leopard" ; then
        echo "tagging leopard/$pkgspec as $tag."
        echo $pkgspec >> leopardsh/tags/$tag.txt
        cat leopardsh/tags/$tag.txt | sort | uniq > $temp
        cat $temp > leopardsh/tags/$tag.txt

        echo $tag >> leopardsh/tags/tags.txt
        cat leopardsh/tags/tags.txt | sort | uniq > $temp
        cat $temp > leopardsh/tags/tags.txt
    fi
    if test -n "$in_leopard64" ; then
        echo "tagging leopard/$pkgspec.ppc64 as $tag."
        echo $pkgspec.ppc64 >> leopardsh/tags/$tag.txt
        cat leopardsh/tags/$tag.txt | sort | uniq > $temp
        cat $temp > leopardsh/tags/$tag.txt

        echo $tag >> leopardsh/tags/tags.txt
        cat leopardsh/tags/tags.txt | sort | uniq > $temp
        cat $temp > leopardsh/tags/tags.txt
    fi
done
rm $temp
