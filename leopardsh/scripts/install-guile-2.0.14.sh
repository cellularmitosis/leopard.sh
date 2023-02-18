#!/bin/bash
# based on templates/build-from-source.sh v6

# Install guile on OS X Leopard / PowerPC.

package=guile
version=2.0.14
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz
description="GNU extension language and Scheme interpreter"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    gmp-4.3.2$ppc64 \
    libunistring-1.0$ppc64 \
    libffi-3.4.2$ppc64 \
    gc-8.2.2$ppc64
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

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

if ! which -s pkg-config-0.29.2 ; then
    leopard.sh pkg-config-0.29.2
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

if test "$(leopard.sh --cpu)" = "g5" ; then
    # Fails on 32-bit G5:
    #   GUILE_INSTALL_LOCALE=1 GUILE_AUTO_COMPILE=0 \
    #   	../meta/build-env				\
    #   	guild compile --target="powerpc-apple-darwin9.8.0" -Wunbound-variable -Warity-mismatch -Wformat	\
    #   	  -L "/tmp/guile-2.0.14/module" -L "/tmp/guile-2.0.14/module"		\
    #   	  -L "/tmp/guile-2.0.14/guile-readline"			\
    #   	  -o "ice-9/eval.go" "ice-9/eval.scm"
    #   Backtrace:
    #   In unknown file:
    #      ?: 5 [apply-smob/1 #<boot-closure 1156550 (_ _ _)> #t ...]
    #      ?: 4 [apply-smob/1 #<catch-closure 11cd980>]
    #      ?: 3 [primitive-eval ((@ # %) (begin # # #))]
    #      ?: 2 [apply-smob/1 #<boot-closure 24a14c0 ()>]
    #      ?: 1 [apply-smob/1 #<boot-closure 25807c0 ()>]
    #      ?: 0 [bytevector-s32-set! #vu8(0 0 0 0) 0 812 big]
    #   
    #   ERROR: make[2]: *** [ice-9/eval.go] Error 1
    exit 1
fi

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --with-threads \
    --with-libgmp-prefix=/opt/gmp-4.3.2$ppc64 \
    --with-libunistring-prefix=/opt/libunistring-1.0$ppc64 \
    PKG_CONFIG=/opt/pkg-config-0.29.2/bin/pkg-config \
    PKG_CONFIG_PATH="/opt/libffi-3.4.2/lib/pkgconfig:/opt/gc-8.2.2/lib/pkgconfig" \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    # 1 failing test:
    #   Running numbers.test
    #   /bin/sh: line 1: 11803 Segmentation fault      CHARSETALIASDIR="/tmp/guile-2.0.14/lib" ${dir}$tst
    #   FAIL: check-guile
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
