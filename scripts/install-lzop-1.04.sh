#!/bin/bash

# Install lzop on OS X Leopard / PowerPC.

package=lzop
version=1.04

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/pkg-config-0.29.2; then
    leopard.sh pkg-config-0.29.2
fi

if ! test -e /opt/lzo-2.10; then
    leopard.sh lzo-2.10
fi
export PKG_CONFIG_PATH="/opt/$dep/lib/pkgconfig:$PKG_CONFIG_PATH"

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://www.lzop.org/download
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version

    pkgconfignames="lzo2"
    # Note: the lzo2.pc file seems busted, it uses -I${includedir}/lzo instead of -I${includedir}.
    # CPPFLAGS=$(pkg-config --cflags-only-I $pkgconfignames)
    CPPFLAGS=-I/opt/lzo-2.10/include
    LDFLAGS=$(pkg-config --libs-only-L $pkgconfignames)
    LIBS=$(pkg-config --libs-only-l $pkgconfignames)
    export CPPFLAGS LDFLAGS LIBS
    ./configure -C --prefix=/opt/$package-$version

    make $(leopard.sh -j)
    # Note: no 'make check' available.
    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/
