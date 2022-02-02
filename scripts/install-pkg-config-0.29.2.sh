#!/bin/bash

# Install pkg-config on OS X Leopard / PowerPC.

package=pkg-config
version=0.29.2

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://$package.freedesktop.org/releases
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version

    for f in configure glib/configure ; do
        perl -pi -e "s/CFLAGS=\"-g -Wall -O2\"/CFLAGS=\"-Wall $(leopard.sh -m64 -mcpu -O)\"/g" $f
        perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(leopard.sh -m64 -mcpu -O)\"/g" $f
        perl -pi -e "s/CFLAGS=\"-g\"/CFLAGS=\"$(leopard.sh -m64 -mcpu -O)\"/g" $f
    done

    ./configure -C --prefix=/opt/$package-$version \
        --with-internal-glib \
        --disable-host-tool
    make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_MAKE_CHECK"; then
        make check
    fi

    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/
