#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install libsndfile on OS X Tiger / PowerPC.

package=libsndfile
version=1.0.28
upstream=http://www.mega-nerd.com/libsndfile/files/$package-$version.tar.gz
description="C library for reading and writing files containing sampled sound"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    libogg-1.3.5$ppc64 \
    libvorbis-1.3.7$ppc64 \
    flac-1.4.2$ppc64 \
    speex-1.2.1$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
done
LIBS="-logg -lvorbis -lFLAC -lspeex"
PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

if ! type -a pkg-config >/dev/null 2>&1 ; then
    tiger.sh pkg-config-0.29.2
fi
export PATH="/opt/pkg-config-0.29.2/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    PKG_CONFIG=/opt/pkg-config-0.29.2/bin/pkg-config \
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
    LDFLAGS="$LDFLAGS" \
    CPPFLAGS="$CPPFLAGS" \
    LIBS="$LIBS"

# /usr/bin/gcc doesn't recognize '-Wvla'.
for f in Makefile */Makefile ; do
    sed -i '' -e 's/-Wvla / /' $f
done

# gcc -std=gnu99 -DHAVE_CONFIG_H -I. -I../src  -I../src  -I/opt/speex-1.2.1/include -I/opt/flac-1.4.2/include -I/opt/libvorbis-1.3.7/include -I/opt/libogg-1.3.5/include  -D_FORTIFY_SOURCE=2  -mcpu=970 -O2 -std=gnu99 -Wall -Wextra -Wdeclaration-after-statement -Wpointer-arith -Wcast-align -Wcast-qual  -Wwrite-strings -Wundef -Wuninitialized -Winit-self -Wbad-function-cast -Wnested-externs -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations   -pipe  -c -o sndfile-play.o sndfile-play.c
# sndfile-play.c:64:27: error: Availability.h: No such file or directory
patch -p1 << 'EOF'
--- libsndfile-1.0.28/programs/sndfile-play.c	2017-04-01 02:18:02.000000000 -0500
+++ libsndfile-1.0.28.patched/programs/sndfile-play.c	2023-02-26 00:22:44.000000000 -0600
@@ -61,7 +61,9 @@
 
 #elif (defined (__MACH__) && defined (__APPLE__))
 	#include <AvailabilityMacros.h>
+#ifdef MAC_OS_X_VERSION_10_5
 	#include <Availability.h>
+#endif
 
 #elif HAVE_SNDIO_H
 	#include <sndio.h>
EOF

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

