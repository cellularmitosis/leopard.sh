#!/bin/bash
# based on templates/build-from-source.sh v6

# Install socat on OS X Leopard / PowerPC.

package=socat
version=1.7.4.4
upstream=http://www.dest-unreach.org/$package/download/$package-$version.tar.gz
description="Multipurpose relay (SOcket CAT) (netcat on steroid)."

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    readline-8.2$ppc64 \
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

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --enable-openssl-base=/opt/libressl-3.4.2 \
    --enable-openssl-method \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS"

# libressl provides an OPENSSL_init_ssl, which causes configure to determine
# HAVE_OPENSSL_INIT_SSL is 1, but libressl does not define OPENSSL_INIT_SETTINGS,
# so the build ends up failing anyway.  libressl provides this signature:
#   int OPENSSL_init_ssl(uint64_t opts, const void *settings);
#
# I tried typedef'ing OPENSSL_INIT_SETTINGS to void:
#   sed -i '' -e '/#if HAVE_OPENSSL_INIT_SSL/a\
#   #define OPENSSL_INIT_SETTINGS void' sslcls.h
#   sed -i '' -e '/#if HAVE_OPENSSL_INIT_SSL/a\
#   #define OPENSSL_INIT_SETTINGS void' sslcls.c
#
# This allows socat to build, but still fails to link:
#   gcc -mcpu=970 -O2 -D_GNU_SOURCE -Wall -Wno-parentheses  -DHAVE_CONFIG_H -I. -I/opt/libressl-3.4.2/include -I/opt/readline-8.2/include  -L/opt/libressl-3.4.2/lib -L/opt/readline-8.2/lib  -o socat socat.o libxio.a -lwrap -lutil -lresolv  -lreadline  -lssl -lcrypto
#   Undefined symbols:
#     "_OPENSSL_INIT_new", referenced from:
#         __xioopen_openssl_prepare in libxio.a(xio-openssl.o)
#   ld: symbol(s) not found
#
# So instead we override config.h to say we don't have OPENSSL_init_ssl.
sed -i '' -e 's/#define HAVE_OPENSSL_INIT_SSL 1/#define HAVE_OPENSSL_INIT_SSL 0/' config.h

/usr/bin/time make $(leopard.sh -j) V=1

# Note: no 'make check' available.

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
