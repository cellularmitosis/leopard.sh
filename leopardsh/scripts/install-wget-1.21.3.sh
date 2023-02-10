#!/bin/bash
# based on templates/build-from-source.sh v6

# Install wget on OS X Leopard / PowerPC.

package=wget
version=1.21.3
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    libressl-3.4.2$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done
LIBS="-lbar -lqux"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if test -z "$ppc64" -a "$(leopard.sh --cpu)" = "g5" ; then
    # A 32-bit G5 build will compile but will fail to run with 'Abort trap',
    # so we instead install the g4e binpkg in that case.
    if leopard.sh --install-binpkg $pkgspec tiger.g4e ; then
        exit 0
    fi
else
    if leopard.sh --install-binpkg $pkgspec ; then
        exit 0
    fi
fi

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
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-ssl=openssl \
    --with-libssl-prefix=/opt/libressl-3.4.2 \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    make check
    # Note: the tests fail to build:
    #     CCLD     wget_cookie_fuzzer
    #   Undefined symbols:
    #     "_fmemopen", referenced from:
    #         _test_parse_netrc in libunittest.a(libunittest_a-netrc.o)
    #   ld: symbol(s) not found
    #   collect2: ld returned 1 exit status
    #   make[3]: *** [wget_cookie_fuzzer] Error 1
fi

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
