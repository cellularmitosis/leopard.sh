#!/bin/bash
# based on templates/build-from-source.sh v6

# Install pkg-config on OS X Leopard / PowerPC.

package=pkg-config
version=0.29.2
upstream=https://$package.freedesktop.org/releases/$package-$version.tar.gz
description="Manage compile and link flags for libraries"

# Note: pkg-config's default search path can be revealed via:
#   $ pkg-config --variable pc_path pkg-config
#   /opt/pkg-config-0.29.2/lib/pkgconfig:/opt/pkg-config-0.29.2/share/pkgconfig

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

# Build was failiing on 32-bit G5 with:
#   libtool: compile:  gcc -DHAVE_CONFIG_H -I. -I.. -I.. -I../glib -I../glib -I.. -DG_LOG_DOMAIN=\"GLib\" -DG_DISABLE_CAST_CHECKS -DGLIB_COMPILATION -DPCRE_STATIC -D_REENTRANT -Wall -Wstrict-prototypes -mcpu=970 -O2 -MT libglib_2_0_la-gvariant.lo -MD -MP -MF .deps/libglib_2_0_la-gvariant.Tpo -c gvariant.c -o libglib_2_0_la-gvariant.o
#   gvariant.c:4428: error: size of array '_GStaticAssertCompileTimeAssertion_4428' is negative
#   make[6]: *** [libglib_2_0_la-gvariant.lo] Error 1
# Thankfully, this MacPorts patch solves the issue:
patchroot=https://raw.githubusercontent.com/macports/macports-ports/master/devel/pkgconfig/files
curl $patchroot/patch-glib-configure.diff | patch -p0

CFLAGS="$(leopard.sh -mcpu -O)"
if test -n "$ppc64" ; then
    CFLAGS="$(leopard.sh -mcpu -O) -m64"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-internal-glib \
    --disable-host-tool \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS"

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
