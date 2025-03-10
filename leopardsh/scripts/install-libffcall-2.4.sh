#!/bin/bash
# based on templates/build-from-source.sh v6

# Install libffcall on OS X Leopard / PowerPC.

package=libffcall
version=2.4
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz
description="Build foreign function call interfaces in embedded interpreters"

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

CFLAGS="$(leopard.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(leopard.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --enable-threads=posix \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS"

# Note: using -j2 seems to break the build (on G5).
/usr/bin/time make V=1

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

# Note: ppc64 fails to build:
# cd avcall && make all
# case "darwin9.8.0" in \
# 	  aix*) syntax=aix;; \
# 	  *) syntax=linux;; \
# 	esac; \
# 	case ${syntax} in \
# 	  linux) \
# 	    gcc -std=gnu99 -E `if test true = true; then echo '-DASM_UNDERSCORE'; fi` ./avcall-powerpc64-${syntax}.S | grep -v '^ *#line' | grep -v '^#' | sed -e 's,% ,%,g' -e 's,//.*$,,' > avcall-powerpc64.s || exit 1 ;; \
# 	  *) \
# 	    cp ./avcall-powerpc64-${syntax}.s avcall-powerpc64.s || exit 1 ;; \
# 	esac
# /bin/sh ../libtool --mode=compile gcc -std=gnu99 -x none -c avcall-powerpc64.s
# libtool: compile:  gcc -std=gnu99 -x none -c avcall-powerpc64.s  -fno-common -DPIC -o .libs/avcall-powerpc64.o
# avcall-powerpc64.c:2:unknown .machine argument: power4
# avcall-powerpc64.c:3:Expected comma after segment-name
# avcall-powerpc64.c:3:Rest of line ignored. 1st junk character valued 32 ( ).
# avcall-powerpc64.c:9:Invalid mnemonic 'tocbase,0'
# avcall-powerpc64.c:10:Unknown pseudo-op: .previous
# avcall-powerpc64.c:11:Unknown pseudo-op: .type
# avcall-powerpc64.c:11:Rest of line ignored. 1st junk character valued 97 (a).
# avcall-powerpc64.c:11:Invalid mnemonic 'function'
# avcall-powerpc64.c:13:Parameter syntax error (parameter 1)
