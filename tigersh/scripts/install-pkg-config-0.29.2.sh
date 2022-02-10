#!/bin/bash

# Install pkg-config on OS X Tiger / PowerPC.

package=pkg-config
version=0.29.2

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

if test -n "$ppc64" ; then
    # Note: pkg-config needs /usr/lib/libresolv.9.dylib, which is 32-bit only
    # on Tiger, so we are stuck with a 32-bit pkg-config until we get a 64-bit
    # build of libresolv.  To continue down this rabbit hole,
    # see https://opensource.apple.com/tarballs/libresolv/
    # This is the error due to the system libresolv being only 32-bit:
    # checking for res_query... configure: error: not found
    # configure: error: ./configure failed for glib
    # Note also that the system iconv is 32-bit only, so you'll need to build
    # iconv as well.
    echo "Error: pkg-config not buildable as ppc64 on Tiger." >&2
    exit 1
fi

pkgspec=$package-$version$ppc64

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://$package.freedesktop.org/releases
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = f6e931e319531b736fadc017f470e68a

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    for f in configure glib/configure ; do
        if test -n "$ppc64" ; then
            perl -pi -e "s/CFLAGS=\"-g -Wall -O2\"/CFLAGS=\"-Wall -m64 $(tiger.sh -mcpu -O)\"/g" $f
            perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"-m64 $(tiger.sh -mcpu -O)\"/g" $f
            perl -pi -e "s/CFLAGS=\"-g\"/CFLAGS=\"-m64 $(tiger.sh -mcpu -O)\"/g" $f
        else
            perl -pi -e "s/CFLAGS=\"-g -Wall -O2\"/CFLAGS=\"-Wall $(tiger.sh -m32 -mcpu -O)\"/g" $f
            perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(tiger.sh -m32 -mcpu -O)\"/g" $f
            perl -pi -e "s/CFLAGS=\"-g\"/CFLAGS=\"$(tiger.sh -m32 -mcpu -O)\"/g" $f
        fi
    done

    ./configure -C --prefix=/opt/$pkgspec \
        --with-internal-glib \
        --disable-host-tool

    make $(tiger.sh -j) V=1

    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi

    make install

    leopard.sh --arch-check $pkgspec

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi
