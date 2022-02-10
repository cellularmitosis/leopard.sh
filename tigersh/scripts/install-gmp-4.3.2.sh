#!/bin/bash
# based on templates/template.sh v3

# Install gmp on OS X Tiger / PowerPC.

package=gmp
version=4.3.2

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.2
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 2a431d487dfd76d0f618d241b1e551cc

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    # Note: /usr/bin/gcc (4.0.1) fails with:
    #   ld: duplicate symbol ___gmpz_abs in .libs/compat.o and .libs/assert.o
    # So we use gcc-4.2 instead.
    # Thanks to https://gmplib.org/list-archives/gmp-bugs/2010-January/001837.html
    export CC=gcc-4.2

    cpu=$(tiger.sh --cpu)

    if test "$cpu" = "g5" ; then
        if test -n "$ppc64" ; then
            CFLAGS="-m64 $(tiger.sh -mcpu -O)"
            CXXFLAGS="-m64 $(tiger.sh -mcpu -O)"
        else
            CFLAGS="-mpowerpc -force_cpusubtype_ALL $(tiger.sh -m32 -mcpu -O)"
            CXXFLAGS="-mpowerpc -force_cpusubtype_ALL $(tiger.sh -m32 -mcpu -O)"
        fi
    elif test "$cpu" = "g4e" -o "$cpu" = "g4" ; then
        CFLAGS="-pedantic -mpowerpc -no-cpp-precomp -force_cpusubtype_ALL -Wa,-maltivec $(tiger.sh -mcpu -O)"
        CXXFLAGS="-pedantic -mpowerpc -no-cpp-precomp -force_cpusubtype_ALL -Wa,-maltivec $(tiger.sh -mcpu -O)"
    elif test "$cpu" = "g3" ; then
        CFLAGS="-pedantic -mpowerpc -no-cpp-precomp -force_cpusubtype_ALL $(tiger.sh -mcpu -O)"
        CXXFLAGS="-pedantic -mpowerpc -no-cpp-precomp -force_cpusubtype_ALL $(tiger.sh -mcpu -O)"
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
                ABI=32
        else
            ./configure -C --prefix=/opt/$pkgspec \
                --enable-cxx
        fi
    fi

    make $(tiger.sh -j)

    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi

    make install

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
