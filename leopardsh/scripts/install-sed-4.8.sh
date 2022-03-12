#!/bin/bash
# based on templates/build-from-source.sh v6

# Install sed on OS X Leopard / PowerPC.

package=sed
version=4.8
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

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

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    # 'make check' fails on ppc64:
    #   CC       test-stdint.o
    # test-stdint.c:264: error: negative width in bit-field '_gl_verify_error_if_negative'
    # test-stdint.c:265: error: negative width in bit-field '_gl_verify_error_if_negative'
    # test-stdint.c:414: error: negative width in bit-field '_gl_verify_error_if_negative'
    # make[5]: *** [test-stdint.o] Error 1
    # make[4]: *** [check-am] Error 2
    # make[3]: *** [check-recursive] Error 1
    # make[2]: *** [check] Error 2
    # make[1]: *** [check-recursive] Error 1
    # make: *** [check] Error 2

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
