#!/bin/bash
# based on templates/build-from-source.sh v6

# Install flex on OS X Leopard / PowerPC.

package=flex
version=2.6.4
upstream=https://github.com/westes/$package/archive/refs/tags/v$version.tar.gz
description="The Fast Lexical Analyzer"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: the tests fail to build with the system bison, so we install bison-3.8.2.
#   gcc -DHAVE_CONFIG_H -I. -I../src  -I../src -I../src   -mcpu=970 -O2 -c -o bison_nr_parser.o bison_nr_parser.c
#   bison_nr_parser.y:61: error: conflicting types for 'YYSTYPE'
#   bison_nr_parser.h:4: error: previous declaration of 'YYSTYPE' was here
#   /usr/share/bison.simple: In function 'testparse':
#   /usr/share/bison.simple:432: warning: passing argument 1 of 'testlex' from incompatible pointer type
#   make[2]: *** [bison_nr_parser.o] Error 1
if ! test -e /opt/bison-3.8.2 ; then
    leopard.sh bison-3.8.2
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

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(leopard.sh -mcpu -O)
CXXFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    YACC=/opt/bison-3.8.2/bin/bison \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS"

/usr/bin/time make $(leopard.sh -j) V=1

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
