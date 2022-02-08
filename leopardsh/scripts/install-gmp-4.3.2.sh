#!/bin/bash
# based on templates/template.sh v3


# Install gmp on OS X Leopard / PowerPC.

package=gmp
version=4.3.2

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
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

    # Note: /usr/bin/gcc (4.0.1) fails with:
    #   ld: duplicate symbol ___gmpz_abs in .libs/compat.o and .libs/assert.o
    # So we use gcc-4.2 instead.
    # Thanks to https://gmplib.org/list-archives/gmp-bugs/2010-January/001837.html
    export CC=gcc-4.2

    cpu=$(leopard.sh --cpu)

    if test "$cpu" = "g5" ; then
        if test -n "$ppc64" ; then
            CFLAGS="-m64 $(leopard.sh -mcpu -O)"
            CXXFLAGS="-m64 $(leopard.sh -mcpu -O)"
        else
            CFLAGS="-mpowerpc64 -force_cpusubtype_ALL $(leopard.sh -mcpu -O)"
            CXXFLAGS="-mpowerpc64 -force_cpusubtype_ALL $(leopard.sh -mcpu -O)"
        fi
    elif test "$cpu" = "g4e" -o "$cpu" = "g4" ; then
        CFLAGS="-pedantic -mpowerpc -no-cpp-precomp -force_cpusubtype_ALL -Wa,-maltivec $(leopard.sh -mcpu -O)"
        CXXFLAGS="-pedantic -mpowerpc -no-cpp-precomp -force_cpusubtype_ALL -Wa,-maltivec $(leopard.sh -mcpu -O)"
    elif test "$cpu" = "g3" ; then
        CFLAGS="-pedantic -mpowerpc -no-cpp-precomp -force_cpusubtype_ALL $(leopard.sh -mcpu -O)"
        CXXFLAGS="-pedantic -mpowerpc -no-cpp-precomp -force_cpusubtype_ALL $(leopard.sh -mcpu -O)"
    fi
    export CFLAGS CXXFLAGS

    if test -n "$ppc64" ; then
        ./configure -C --prefix=/opt/$pkgspec \
            --enable-cxx \
            ABI=mode64
    else
        if test "$cpu" = "g5" ; then
            ./configure -C --prefix=/opt/$pkgspec \
                --enable-cxx \
                ABI=mode32
        else
            ./configure -C --prefix=/opt/$pkgspec \
                --enable-cxx
        fi
    fi

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
