#!/bin/bash
# based on templates/build-from-source.sh v6

# Install glib on OS X Leopard / PowerPC.

package=glib
version=1.2.10
upstream=https://download.gnome.org/sources/glib/1.2/$package-$version.tar.gz
description="A library of C routines for the GTK+ project"

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

# Thanks to https://web.archive.org/web/20060709235331/https://www.linuxfromscratch.org/patches/blfs/svn/glib-1.2.10-gcc34-1.patch
patch -p1 << 'EOF'
Submitted By: Uwe Düffert (lfs at uwe-dueffert dot de)
Date: 2004-05-15
Initial Package Version: 1.2.10
Origin: self-created, http://www.uwe-dueffert.de/lfs/ownpatches/glib-1.2.10-gcc34-1.patch
Upstream Status: not reported
Description: fix compilation of glib1 with gcc34

diff -Naur glib-1.2.10.orig/gstrfuncs.c glib-1.2.10/gstrfuncs.c
--- glib-1.2.10.orig/gstrfuncs.c	2004-05-15 13:40:03.556092792 +0000
+++ glib-1.2.10/gstrfuncs.c	2004-05-15 13:40:36.712052320 +0000
@@ -47,6 +47,8 @@
  * inteferes with g_strsignal() on some OSes
  */

+#define G_GNUC_PRETTY_FUNCTION
+
 typedef union  _GDoubleIEEE754  GDoubleIEEE754;
 #define G_IEEE754_DOUBLE_BIAS   (1023)
 /* multiply with base2 exponent to get base10 exponent (nomal numbers) */
EOF

CFLAGS="$(leopard.sh -mcpu -O) $CFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

# Note: --enable-shared doesn't appear to work.
/usr/bin/time \
    env CFLAGS="$CFLAGS" \
        ./configure --prefix=/opt/$pkgspec \
            --disable-dependency-tracking \
            --host=powerpc-unknown-bsd \
            --target=powerpc-unknown-bsd

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

make install

# An attempt and making dylibs...
gcc $CFLAGS -dynamiclib \
    -install_name /opt/glib-1.2.10/lib/libglib.1.dylib \
    -compatibility_version 1.2 \
    -current_version 1.2.10 \
    -o libglib.1.2.10.dylib \
    garray.o gcache.o gcompletion.o gdataset.o \
    gdate.o gerror.o ghash.o ghook.o giochannel.o giounix.o glist.o \
    gmain.o gmem.o gmessages.o gmutex.o gnode.o gprimes.o grel.o \
    gscanner.o gslist.o gstrfuncs.o gstring.o gtimer.o gtree.o \
    gutils.o

libname=glib
cp lib${libname}.1.2.10.dylib /opt/$pkgspec/lib/
cd /opt/$pkgspec/lib
ln -s lib${libname}.1.2.10.dylib lib${libname}.dylib
ln -s lib${libname}.1.2.10.dylib lib${libname}.1.dylib
ln -s lib${libname}.1.2.10.dylib lib${libname}.1.2.dylib
cd -

gcc $CFLAGS -dynamiclib \
    -install_name /opt/glib-1.2.10/lib/libgmodule.1.dylib \
    -compatibility_version 1.2 \
    -current_version 1.2.10 \
    -o libgmodule.1.2.10.dylib \
    gmodule/gmodule.o \
    -L/opt/glib-1.2.10/lib -lglib

libname=gmodule
cp lib${libname}.1.2.10.dylib /opt/$pkgspec/lib/
cd /opt/$pkgspec/lib
ln -s lib${libname}.1.2.10.dylib lib${libname}.dylib
ln -s lib${libname}.1.2.10.dylib lib${libname}.1.dylib
ln -s lib${libname}.1.2.10.dylib lib${libname}.1.2.dylib
cd -

gcc $CFLAGS -dynamiclib \
    -install_name /opt/glib-1.2.10/lib/libgthread.1.dylib \
    -compatibility_version 1.2 \
    -current_version 1.2.10 \
    -o libgthread.1.2.10.dylib \
    gthread/gthread.o \
    -L/opt/glib-1.2.10/lib -lglib

libname=gthread
cp lib${libname}.1.2.10.dylib /opt/$pkgspec/lib/
cd /opt/$pkgspec/lib
ln -s lib${libname}.1.2.10.dylib lib${libname}.dylib
ln -s lib${libname}.1.2.10.dylib lib${libname}.1.dylib
ln -s lib${libname}.1.2.10.dylib lib${libname}.1.2.dylib
cd -

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
