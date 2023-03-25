#!/bin/bash
# based on templates/build-from-source.sh v6

# Install janet on OS X Leopard / PowerPC.

package=janet
version=1.27.0
upstream=https://github.com/janet-lang/janet/archive/refs/tags/v$version.tar.gz

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

dep=macports-legacy-support-20221029$ppc64
if ! test -e /opt/$dep ; then
    leopard.sh $dep
fi
CPPFLAGS="-I/opt/$dep/include/LegacySupport $CPPFLAGS"
LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
PATH="/opt/$dep/bin:$PATH"
LIBS="-lMacportsLegacySupport"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if test -z "$ppc64" -a "$(leopard.sh --cpu)" = "g5" ; then
    # janet on G5's has a lot of malloc errors:
    #   janet(73818) malloc: *** error for object 0x80000: pointer being freed was not allocated
    #   *** set a breakpoint in malloc_error_break to debug
    # So we instead install the g4e binpkg in that case.
    if leopard.sh --install-binpkg $pkgspec leopard.g4e ; then
        exit 0
    fi
else
    if leopard.sh --install-binpkg $pkgspec ; then
        exit 0
    fi
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

# Janet needs thread-local storage.
if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9.4
fi
CC=gcc-4.9

if ! test -e /opt/make-4.3 ; then
    leopard.sh make-4.3
fi
export PATH="/opt/make-4.3/bin:$PATH"

if ! test -e /opt/ld64-97.17-tigerbrew ; then
    leopard.sh ld64-97.17-tigerbrew
fi
export PATH="/opt/ld64-97.17-tigerbrew/bin:$PATH"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

sed -i '' -e "s|COMMON_CFLAGS:=|COMMON_CFLAGS:= $CPPFLAGS |" Makefile
sed -i '' -e "s|CLIBS=|CLIBS= $LDFLAGS $LIBS |" Makefile

CFLAGS="$(leopard.sh -mcpu -O)"

/usr/bin/time make $(leopard.sh -j) \
    PREFIX=/opt/$pkgspec \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CC="$CC"

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make test
fi

make install PREFIX=/opt/$pkgspec

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
