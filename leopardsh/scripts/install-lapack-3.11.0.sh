#!/bin/bash
# based on templates/build-from-source.sh v6

# Install LAPACK on OS X Leopard / PowerPC.

package=lapack
version=3.11.0
upstream=https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v$version.tar.gz
description="Linear Algebra PACKage"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

dep=xblas-1.0.248$ppc64
if ! test -e /opt/$dep ; then
    leopard.sh $dep
fi

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

dep=python-3.11.2
if ! test -e /opt/$dep ; then
    leopard.sh $dep
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS="$(leopard.sh -mcpu -O)"
LDFLAGS=""
M64=""
if test -n "$ppc64" ; then
    M64="-m64"
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

cat > make.inc << EOF
SHELL = /bin/sh
CC = gcc-4.9
CFLAGS = $CFLAGS
FC = gfortran-4.9
FFLAGS = $CFLAGS -frecursive
FFLAGS_DRV = \$(FFLAGS)
FFLAGS_NOOPT = $M64 -O0 -frecursive
LDFLAGS = $LDFLAGS
AR = ar
ARFLAGS = cr
RANLIB = ranlib
TIMER = INT_ETIME
LAPACKE_WITH_TMG = Yes
USEXBLAS = Yes
XBLASLIB = /opt/xblas-1.0.248$ppc64/lib/libxblas_.a
BLASLIB = \$(TOPSRCDIR)/libblas.a
CBLASLIB = \$(TOPSRCDIR)/libcblas.a
LAPACKLIB = \$(TOPSRCDIR)/liblapack.a
TMGLIB = \$(TOPSRCDIR)/libtmglib.a
LAPACKELIB = \$(TOPSRCDIR)/liblapacke.a
DOCSDIR = \$(TOPSRCDIR)/DOCS
EOF

make $(leopard.sh -j)
cd CBLAS
make $(leopard.sh -j)
cd ../LAPACKE
make $(leopard.sh -j)
cd ..

# Note: tests are run as part of 'make'.

mkdir -p /opt/$pkgspec/lib
cp libblas.a libcblas.a liblapack.a liblapacke.a libtmglib.a /opt/$pkgspec/lib/

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
