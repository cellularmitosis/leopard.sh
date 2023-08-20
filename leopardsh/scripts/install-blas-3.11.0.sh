#!/bin/bash
# based on templates/build-from-source.sh v6

# Install BLAS on OS X Leopard / PowerPC.

package=blas
version=3.11.0
upstream=http://www.netlib.org/$package/$package-$version.tgz
description="Basic Linear Algebra Subprograms"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gcc-4.9.4 ; then
    leopard.sh gcc-libs-4.9.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

FLAGS="$(leopard.sh -mcpu -O) -fPIC"
if test -n "$ppc64" ; then
    FLAGS="-m64 $FLAGS"
fi

# Thanks to https://bizhishui.github.io/Build-Netlib
# Build a shared lib.
gfortran-4.9 $FLAGS -shared *.f *.f90 -o libblas.dylib
# Build a static lib.
gfortran-4.9 $FLAGS -c *.f *.f90
ar cr libblas.a *.o

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    cd TESTING
    make run FC=gfortran-4.9 PLAT=''
    cd -
    make check
fi

mkdir -p /opt/$pkgspec/lib
ln -s libblas.a blas.a
mv libblas.dylib libblas.a blas.a /opt/$pkgspec/lib/

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
