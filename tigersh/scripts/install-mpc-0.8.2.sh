#!/bin/bash
# based on templates/template.sh v3

# Install mpc on OS X Tiger / PowerPC.

package=mpc
version=0.8.2

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

echo -n -e "\033]0;tiger.sh $pkgspec ($(hostname -s))\007"

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

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    cpu=$(tiger.sh --cpu)

    if test "$cpu" = "g5" ; then
        if test -n "$ppc64" ; then
            CFLAGS="-m64 $(tiger.sh -mcpu -O)"
        else
            CFLAGS="-pedantic -mpowerpc -no-cpp-precomp -force_cpusubtype_ALL -Wa,-maltivec $(tiger.sh -m32 -mcpu -O)"
        fi
    elif test "$cpu" = "g4e" -o "$cpu" = "g4" ; then
        CFLAGS="-pedantic -mpowerpc -no-cpp-precomp -force_cpusubtype_ALL -Wa,-maltivec $(tiger.sh -m32 -mcpu -O)"
    elif test "$cpu" = "g3" ; then
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

# failing on tiger:
# libtool: compile:  gcc -DHAVE_CONFIG_H -I. -I.. -I/opt/gmp-4.3.2/include -I/opt/mpfr-3.1.6/include -mcpu=7400 -Os -MT abs.lo -MD -MP -MF .deps/abs.Tpo -c abs.c  -fno-common -DPIC -o .libs/abs.o
# acos.c: In function 'mpc_acos':
# acos.c:192: error: 'GMP_RNDA' undeclared (first use in this function)
# acos.c:192: error: (Each undeclared identifier is reported only once
# acos.c:192: error: for each function it appears in.)
# libtool: compile:  gcc -DHAVE_CONFIG_H -I. -I.. -I/opt/gmp-4.3.2/include -I/opt/mpfr-3.1.6/include -mcpu=7400 -Os -MT abs.lo -MD -MP -MF .deps/abs.Tpo -c abs.c -o abs.o >/dev/null 2>&1
# make[2]: *** [acos.lo] Error 1
# make[2]: *** Waiting for unfinished jobs....
# mv -f .deps/abs.Tpo .deps/abs.Plo
# make[2]: *** Waiting for unfinished jobs....
# make[1]: *** [all-recursive] Error 1
# make: *** [all] Error 2

# according to this link, GMP_RNDA was removed in mpfr-3.x, and this was worked-around in mpc-0.8.2:
# https://sourceware.org/legacy-ml/crossgcc/2010-06/msg00043.html
