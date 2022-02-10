#!/bin/bash
# based on templates/template.sh v3

# Install gcc on OS X Tiger / PowerPC.

package=gcc
version=4.9.4

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

if ! test -e /opt/gmp-4.3.2$ppc64 ; then
    tiger.sh gmp-4.3.2$ppc64
fi

if ! test -e /opt/mpfr-3.1.6$ppc64 ; then
    tiger.sh mpfr-3.1.6$ppc64
fi

if ! test -e /opt/mpc-1.0.3$ppc64 ; then
    tiger.sh mpc-1.0.3$ppc64
fi

if ! test -e /opt/isl-0.12.2$ppc64 ; then
    tiger.sh isl-0.12.2$ppc64
fi

if ! test -e /opt/cloog-0.18.1$ppc64 ; then
    tiger.sh cloog-0.18.1$ppc64
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package/$package-$version
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = b92b423b2f8f517c909fda2621ff2d7c

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    export CC=gcc-4.2 CXX=g++-4.2

    # Note: I haven't figured out how to get gcc to build using custom flags,
    # nor how to build a 64-bit gcc on G5.

    ./configure -C \
        --prefix=/opt/$pkgspec \
        --with-gmp=/opt/gmp-4.3.2$ppc64 \
        --with-mpc=/opt/mpc-1.0.3$ppc64 \
        --with-mpfr=/opt/mpfr-3.1.6$ppc64 \
        --with-isl=/opt/isl-0.12.2$ppc64 \
        --with-cloog=/opt/cloog-0.18.1$ppc64 \
        --enable-languages=c,c++,objc,obj-c++,fortran \
        --enable-libssp \
        --enable-lto \
        --enable-objc-gc \
        --enable-shared \
        --program-suffix=-4.9 \
        --disable-bootstrap

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

# --enable-languages=c,c++,objc,obj-c++,fortran,java \
# --enable-libada \
# see https://sourceforge.net/projects/gnuada/files/GNAT_GPL%20Mac%20OS%20X/2009-tiger-ppc/
