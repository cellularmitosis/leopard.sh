#!/bin/bash
# based on templates/build-from-source.sh v6

# Install XBLAS on OS X Leopard / PowerPC.

package=xblas
version=1.0.248
upstream=http://www.netlib.org/xblas/xblas.tar.gz
description="Extra Precise Basic Linear Algebra Subroutines"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Note: LAPACK seems to expect trailing underscores on all symbols.
# We'll build once with (libxblas_.a) and once without (libxblas.a) trailing underscores.

CFLAGS="$(leopard.sh -mcpu -O)"
LDFLAGS=""
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

cat > make.inc << EOF
XBLASLIB = libxblas.a
CC = gcc
CFLAGS = $CFLAGS
LINKER = \$(CC)
LDFLAGS = $LDFLAGS
ARCH         = ar
ARCHFLAGS    = cr
RANLIB       = ranlib
EXTRA_LIBS =  -lm
M4 	= m4
M4_OPTS =  -D no_f2c
INDENT	= indent
INDENT_OPTS = 
EOF

make $(leopard.sh -j)
mkdir -p /opt/$pkgspec/lib
cp libxblas.a /opt/$pkgspec/lib

make clean

cat > make.inc << EOF
XBLASLIB = libxblas_.a
CC = gcc
CFLAGS = $CFLAGS -DCONFIG_FC_UNDERSCORE
LINKER = \$(CC)
LDFLAGS = $LDFLAGS
ARCH         = ar
ARCHFLAGS    = cr
RANLIB       = ranlib
EXTRA_LIBS =  -lm
M4 	= m4
M4_OPTS =  -D no_f2c
INDENT	= indent
INDENT_OPTS = 
EOF

make $(leopard.sh -j)
cp libxblas_.a /opt/$pkgspec/lib

mkdir -p /opt/$pkgspec/share/doc/$pkgspec
cp README doc/report.ps /opt/$pkgspec/share/doc/$pkgspec/

# Note: tests are run automatically during 'make'.

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
