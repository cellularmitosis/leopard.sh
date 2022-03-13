#!/bin/bash
# based on templates/build-from-source.sh v6

# Install gcc on OS X Leopard / PowerPC.

package=gcc
version=4.9.4
upstream=https://ftp.gnu.org/gnu/$package/$package-$version/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    gmp-4.3.2$ppc64 \
    mpfr-3.1.6$ppc64 \
    mpc-1.0.3$ppc64 \
    isl-0.12.2$ppc64 \
    cloog-0.18.1$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
fi

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CC=gcc-4.2
CXX=g++-4.2

# Note: I haven't figured out how to get gcc to build using custom flags,
# nor how to build a 64-bit gcc on G5.

/usr/bin/time ./configure -C \
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
    # --disable-bootstrap

/usr/bin/time make $(leopard.sh -j)

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

# --enable-languages=c,c++,objc,obj-c++,fortran,java \
# --enable-libada \
# see https://sourceforge.net/projects/gnuada/files/GNAT_GPL%20Mac%20OS%20X/2009-tiger-ppc/
