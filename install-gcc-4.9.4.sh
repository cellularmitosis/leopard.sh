#!/bin/bash

# Install gcc on OS X Leopard / PowerPC.

package=gcc
version=4.9.4

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if ! which -s gcc-4.2; then
    leopard.sh gcc-4.2
fi

if ! test -e /opt/gmp-4.3.2; then
    leopard.sh gmp-4.3.2
fi

if ! test -e /opt/mpfr-2.4.2; then
    leopard.sh mpfr-2.4.2
fi

if ! test -e /opt/mpc-0.8.1; then
    leopard.sh mpc-0.8.1
fi

if ! test -e /opt/isl-0.11.1; then
    leopard.sh isl-0.11.1
fi

if ! test -e /opt/cloog-0.18.1; then
    leopard.sh cloog-0.18.1
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package/$package-$version
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version
    CC=gcc-4.2 CXX=g++-4.2 ./configure \
        --prefix=/opt/$package-$version \
        --with-gmp=/opt/gmp-4.3.2 \
        --with-mpc=/opt/mpc-0.8.1 \
        --with-mpfr=/opt/mpfr-2.4.2 \
        --with-isl=/opt/isl-0.11.1 \
        --with-cloog=/opt/cloog-0.18.1 \
        --enable-languages=c,c++,objc,obj-c++,fortran \
        --enable-libssp \
        --enable-lto \
        --enable-objc-gc \
        --program-suffix=-4.9
    make

    if test -n "$LEOPARDSH_MAKE_CHECK"; then
        make check
    fi

    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/

        # --enable-languages=c,c++,objc,obj-c++,fortran,java \
        # --enable-libada \
# see https://sourceforge.net/projects/gnuada/files/GNAT_GPL%20Mac%20OS%20X/2009-tiger-ppc/
