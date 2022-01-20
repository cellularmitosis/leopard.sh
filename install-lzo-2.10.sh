#!/bin/bash

# Install lzo on OS X Leopard / PowerPC.

package=lzo
version=2.10

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/$binpkg | gunzip | tar x
else
    srcmirror=http://www.oberhumer.com/opensource/$package/download
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version
    ./configure --prefix=/opt/$package-$version
    make
    # Note: no 'make check' available.
    make install
fi
