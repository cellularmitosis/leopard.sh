#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install pkg-config on OS X Tiger / PowerPC.

package=pkg-config
version=0.29.2
upstream=https://$package.freedesktop.org/releases/$package-$version.tar.gz
description="Manage compile and link flags for libraries"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if test -n "$ppc64" ; then
    # Note: pkg-config needs /usr/lib/libresolv.9.dylib, which is 32-bit only
    # on Tiger, so we are stuck with a 32-bit pkg-config until we get a 64-bit
    # build of libresolv.  To continue down this rabbit hole,
    # see https://opensource.apple.com/tarballs/libresolv/
    # This is the error due to the system libresolv being only 32-bit:
    # checking for res_query... configure: error: not found
    # configure: error: /usr/bin/time ./configure failed for glib
    # Note also that the system iconv is 32-bit only, so you'll need to build
    # iconv as well.
    echo "Error: pkg-config not buildable as ppc64 on Tiger." >&2
    exit 1
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Build was failiing on 32-bit G5 with:
#   libtool: compile:  gcc -DHAVE_CONFIG_H -I. -I.. -I.. -I../glib -I../glib -I.. -DG_LOG_DOMAIN=\"GLib\" -DG_DISABLE_CAST_CHECKS -DGLIB_COMPILATION -DPCRE_STATIC -D_REENTRANT -Wall -Wstrict-prototypes -mcpu=970 -O2 -MT libglib_2_0_la-gvariant.lo -MD -MP -MF .deps/libglib_2_0_la-gvariant.Tpo -c gvariant.c -o libglib_2_0_la-gvariant.o
#   gvariant.c:4428: error: size of array '_GStaticAssertCompileTimeAssertion_4428' is negative
#   make[6]: *** [libglib_2_0_la-gvariant.lo] Error 1
# Thankfully, this MacPorts patch solves the issue:
patchroot=https://raw.githubusercontent.com/macports/macports-ports/master/devel/pkgconfig/files
curl $patchroot/patch-glib-configure.diff | patch -p0

CFLAGS="$(tiger.sh -mcpu -O)"
if test -n "$ppc64" ; then
    CFLAGS="$(tiger.sh -mcpu -O) -m64"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-internal-glib \
    --disable-host-tool \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
