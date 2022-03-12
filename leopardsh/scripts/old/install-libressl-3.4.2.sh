#!/bin/bash
# based on templates/template.sh v3

# Install libressl on OS X Leopard / PowerPC.

package=libressl
version=3.4.2

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
upstream=https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 18aa728e7947a30af3bb04243e4482aa

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd /tmp/$package-$version


    CFLAGS=$(leopard.sh -mcpu -O)
    if test -n "$ppc64" ; then
        CFLAGS="-m64 $CFLAGS"
    fi

    /usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
        CFLAGS="$CFLAGS"

    /usr/bin/time make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        make check
    fi

    make install

    leopard.sh --linker-check $pkgspec
    leopard.sh --arch-check $pkgspec $ppc64

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
        gzip -9 config.cache
        mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
    fi
fi


