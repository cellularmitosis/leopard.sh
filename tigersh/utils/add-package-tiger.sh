#!/bin/bash

# add a package to ~/leopard.sh/{leopardsh|tigersh}/packages{.ppc64}.txt

if test -z "$1" ; then
    echo "Error: add which pkgspec?" >&2
    echo "e.g. $0 gzip-1.11" >&2
    exit 1
fi

set -e -o pipefail

pkgspec=$1
shift 1

if test "$( echo $pkgspec | rev | cut -d. -f1 | rev )" = "ppc64" ; then
    ppc64=1
fi

if test "$( basename $0 )" = "add-package-tiger.sh" ; then
    if test -n "$ppc64" ; then
        packages=leopardsh/packages.ppc64.txt
    else
        packages=tigersh/packages.txt
    fi
elif test "$( basename $0 )" = "add-package-leopard.sh" ; then
    if test -n "$ppc64" ; then
        packages=leopardsh/packages.ppc64.txt
    else
        packages=leopardsh/packages.txt
    fi
else
    echo "nope!" >&2 
    exit 1
fi

cd ~/leopard.sh
echo $pkgspec >> $packages
temp=$(mktemp)
cat $packages | sort | uniq > $temp
cat $temp > $packages
rm $temp
