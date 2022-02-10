#!/bin/bash
# based on templates/template.sh v3

# Install mpc on OS X Tiger / PowerPC.

package=mpc
version=1.0.3

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gmp-4.3.2$ppc64 ; then
    tiger.sh gmp-4.3.2$ppc64
fi

if ! test -e /opt/mpfr-3.1.6$ppc64 ; then
    tiger.sh mpfr-3.1.6$ppc64
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --os.cpu))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://gcc.gnu.org/pub/gcc/infrastructure
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = d6a1d5f8ddea3abd2cc3e98f58352d26

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    if test "$(tiger.sh --cpu)" = "g5" ; then
        if test -n "$ppc64" ; then
            CFLAGS="-m64 $(tiger.sh -mcpu -O)"
        else
            CFLAGS="-mpowerpc -force_cpusubtype_ALL $(tiger.sh -m32 -mcpu -O)"
        fi
    else
        CFLAGS="-pedantic -mpowerpc -no-cpp-precomp -force_cpusubtype_ALL $(tiger.sh -m32 -mcpu -O)"
    fi
    export CFLAGS

    ./configure -C --prefix=/opt/$pkgspec \
        --with-gmp=/opt/gmp-4.3.2$ppc64 \
        --with-mpfr=/opt/mpfr-3.1.6$ppc64

    make $(tiger.sh -j)

    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi

    make install

    tiger.sh --linker-check $pkgspec
    tiger.sh --arch-check $pkgspec $ppc64

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
