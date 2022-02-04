#!/bin/bash

# Install guile on OS X Leopard / PowerPC.

package=guile
version=3.0.7

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if ! test -e /opt/gcc-4.9.4; then
    leopard.sh gcc-4.9.4
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version
    # Note: guile 3 needs c11 (i.e. gcc-4.9.4).
    # FIXME take a closer look at the available options.
    CC=/opt/gcc-4.9.4/bin/gcc ./configure -C --prefix=/opt/$package-$version
    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS"; then
        make check
    fi

    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/
