#!/bin/bash
# based on templates/template.sh v3

# Install mpc on OS X Leopard / PowerPC.

package=mpc
version=0.8.2

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gmp-4.3.2$ppc64 ; then
    leopard.sh gmp-4.3.2$ppc64
fi

if ! test -e /opt/mpfr-3.1.6$ppc64 ; then
    leopard.sh mpfr-3.1.6$ppc64
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://gcc.gnu.org/pub/gcc/infrastructure
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache > config.cache

    if test "$(leopard.sh --cpu)" = "g5" ; then
        if test -n "$ppc64" ; then
            CFLAGS="-m64 $(leopard.sh -mcpu -O)"
        else
            CFLAGS="-mpowerpc -force_cpusubtype_ALL $(leopard.sh -m32 -mcpu -O)"
        fi
    else
        CFLAGS="-pedantic -mpowerpc -no-cpp-precomp -force_cpusubtype_ALL $(leopard.sh -m32 -mcpu -O)"
    fi
    export CFLAGS

    ./configure -C --prefix=/opt/$pkgspec \
        --with-gmp=/opt/gmp-4.3.2$ppc64 \
        --with-mpfr=/opt/mpfr-3.1.6$ppc64

    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        make check
    fi

    make install

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi
