#!/bin/bash

# Install lzop on OS X Leopard / PowerPC.

package=lzop
version=1.04

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

for dep in \
    lzo-2.10 \
    pkg-config-0.29.2
do
    if ! test -e /opt/$dep; then
        leopard.sh $dep
    fi
    PKG_CONFIG_PATH="/opt/$dep/lib/pkgconfig:$PKG_CONFIG_PATH"
done
export PKG_CONFIG_PATH

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
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

    make
    # Note: no 'make check' available.
    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/
