#!/bin/bash

# start working on installer scripts for a new pkgspec.

set -e

if test -z "$1" ; then
    echo "usage: $0 <pkgspec>" >&2
    exit 1
fi
pkgspec="$1"

set -x

cd ~/leopard.sh
for bigcat in tiger leopard ; do
    cd ${bigcat}sh/scripts
    cp templates/build-from-source.sh install-$pkgspec.sh
    ln -s install-$pkgspec.sh install-$pkgspec.ppc64.sh
    cd -
done
