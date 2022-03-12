#!/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install libsigsegv on OS X Leopard / PowerPC.

package=libsigsegv
version=2.14

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
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 63a2b35f11b2fbccc3d82f9e6c6afd58

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd /tmp/$package-$version


    CFLAGS=$(leopard.sh -mcpu -O)
    if test -n "$ppc64" ; then
        CFLAGS="-m64 $CFLAGS"
        # LDFLAGS="-m64 $LDFLAGS"
    fi

    /usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
        --enable-shared \
        CFLAGS="$CFLAGS" \
        # LDFLAGS="$LDFLAGS"

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


