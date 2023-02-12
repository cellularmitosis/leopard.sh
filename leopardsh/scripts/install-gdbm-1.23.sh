#!/bin/bash
# based on templates/build-from-source.sh v6

# Install gdbm on OS X Leopard / PowerPC.

package=gdbm
version=1.23
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz
description="GNU dbm database routines"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    libiconv-1.16$ppc64 \
    gettext-0.21$ppc64 \
    readline-8.2$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
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

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --with-libiconv-prefix=/opt/libiconv-1.16$ppc64 \
    --with-libintl-prefix=/opt/gettext-0.21$ppc64 \
    --with-readline \
    --enable-libgdbm-compat \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    # libtool: link: gcc -mcpu=7450 -O2 -o t_wordwrap t_wordwrap.o  -L/opt/readline-8.2/lib -L/opt/gettext-0.20/lib -L/opt/libiconv-1.16/lib ../tools/libgdbmapp.a
    # /usr/libexec/gcc/powerpc-apple-darwin8/4.0.1/ld: Undefined symbols:
    # _libintl_setlocale
    # collect2: ld returned 1 exit status
    # make[3]: *** [t_wordwrap] Error 1
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
