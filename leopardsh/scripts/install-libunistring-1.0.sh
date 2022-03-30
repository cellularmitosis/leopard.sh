#!/bin/bash
# based on templates/build-from-source.sh v6

# Install libunistring on OS X Leopard / PowerPC.

package=libunistring
version=1.0
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: we use libiconv-bootstrap to break a dependency cycle with libiconv.
for dep in \
    libiconv-bootstrap-1.16$ppc64
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

# 👇 EDIT HERE:
if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
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
    --with-libiconv-prefix=/opt/libiconv-bootstrap-1.16$ppc64 \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    # Note: tests faile to compile on leopard ppc64:
    # gcc -std=gnu99 -DHAVE_CONFIG_H -DEXEEXT=\"\" -I. -I. -I../lib -I..  -DIN_LIBUNISTRING_GNULIB_TESTS=1 -I. -I. -I.. -I./.. -I../lib -I./../lib   -Wno-error -m64 -mcpu=970 -O2 -MT test-stdint.o -MD -MP -MF $depbase.Tpo -c -o test-stdint.o test-stdint.c &&\
    # mv -f $depbase.Tpo $depbase.Po
    # test-stdint.c:265: error: negative width in bit-field '_gl_verify_error_if_negative'
    # test-stdint.c:266: error: negative width in bit-field '_gl_verify_error_if_negative'
    # test-stdint.c:415: error: negative width in bit-field '_gl_verify_error_if_negative'
    # make[4]: *** [test-stdint.o] Error 1
    # make[3]: *** [check-am] Error 2
    # make[2]: *** [check-recursive] Error 1
    # make[1]: *** [check] Error 2
    # make: *** [check-recursive] Error 1

    # Note: one failing test on leopard ppc:
    # ../build-aux/test-driver: line 112: 25828 Abort trap              "$@" >> "$log_file" 2>&1
    # FAIL: test-float

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
