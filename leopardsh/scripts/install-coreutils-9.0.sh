#!/bin/bash
# based on templates/build-from-source.sh v6

# Install coreutils on OS X Leopard / PowerPC.

package=coreutils
version=9.0
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

# note: fails to build on ppc64.
#if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
#    ppc64=".ppc64"
#fi

pkgspec=$package-$version$ppc64

for dep in \
    gettext-0.21$ppc64 \
    gmp-4.3.2$ppc64 \
    libiconv-1.16$ppc64 \
    libressl-3.4.2$ppc64
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

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

# Note: coreutils ends up linking against /usr/lib/libiconv, despite having
# used --with-libiconv-prefix=/opt/libiconv...:
#   $ otool -L /opt/coreutils-9.0/bin/* | grep /usr/lib/libiconv
#   /usr/lib/libiconv.2.dylib (compatibility version 7.0.0, current version 7.0.0)
# My guess is that this is some bad interaction between --with-libiconv-prefix and
# --with-libintl-prefix, based on this configure output:
#   checking how to link with libiconv... -L/opt/libiconv-1.16/lib -liconv
#   checking how to link with libintl... -L/opt/gettext-0.21/lib -lintl -liconv -Wl,-framework -Wl,CoreFoundation
# You end up with some correct lines:
#   gcc-4.2 -std=gnu99   -mcpu=7450 -O2   -o src/factor src/factor.o src/libver.a lib/libcoreutils.a -L/opt/gettext-0.21/lib -lintl -liconv -Wl,-framework -Wl,CoreFoundation lib/libcoreutils.a  -L/opt/libiconv-1.16/lib -liconv 
# and some which are incorrect:
#   gcc-4.2 -std=gnu99   -mcpu=7450 -O2   -o src/chroot src/chroot.o src/libver.a lib/libcoreutils.a -L/opt/gettext-0.21/lib -lintl -liconv -Wl,-framework -Wl,CoreFoundation lib/libcoreutils.a 
# Coreutils alse ends up linking against /usr/lib/libcrypto:
#   $ otool -L /opt/coreutils-9.0/bin/* | grep /usr/lib/libcrypto
#   /usr/lib/libcrypto.0.9.7.dylib (compatibility version 0.9.7, current version 0.9.7)
# So we need to use CPPFLAGS and LDFLAGS to overcome this.

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-openssl=yes \
    --with-libiconv-prefix=/opt/libiconv-1.16$ppc64 \
    --with-libgmp-prefix=/opt/gmp-4.3.2$ppc64 \
    --with-libintl-prefix=/opt/gettext-0.21$ppc64 \
    CFLAGS="$CFLAGS" \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS"

# On Leopard, coreutils attempts to build libstdbuf, but it fails due to bad
# flags (i.e. -shared instead of -dynamiclib, etc).  Disable it:
perl -pi -e "s|pkglibexec_PROGRAMS = src/libstdbuf.so|pkglibexec_PROGRAMS = |" Makefile

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    # Note: three test failures on ppc32:
    # FAIL: tests/misc/env-S
    # FAIL: tests/misc/sort-continue
    # FAIL: tests/misc/sort-merge-fdlimit
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
