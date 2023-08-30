#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install libgif on OS X Tiger / PowerPC.

package=libgif
version=5.2.1
upstream=https://newcontinuum.dl.sourceforge.net/project/giflib/giflib-$version.tar.gz
description="Graphics Interchange Format library"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.2
fi
CC=gcc-4.2

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

patch -p1 << 'EOF'
--- a/Makefile	2023-08-20 16:36:34.000000000 -0500
+++ b/Makefile	2023-08-20 17:03:29.000000000 -0500
@@ -6,9 +6,8 @@
 # of code space in the shared library.
 
 #
-OFLAGS = -O0 -g
 OFLAGS  = -O2
-CFLAGS  = -std=gnu99 -fPIC -Wall -Wno-format-truncation $(OFLAGS)
+CFLAGS  = -std=gnu99 -fPIC -Wall $(OFLAGS)
 
 SHELL = /bin/sh
 TAR = tar
@@ -61,27 +60,39 @@
 
 LDLIBS=libgif.a -lm
 
-all: libgif.so libgif.a libutil.so libutil.a $(UTILS)
-	$(MAKE) -C doc
+UNAME?=$(shell uname -s)
+
+ifeq ($(UNAME), Darwin)
+	SO=dylib
+        GIF_SOFLAGS:=-shared
+        UTIL_SOFLAGS:=-shared
+else
+	SO=so
+        GIF_SOFLAGS:=-shared -Wl,-soname -Wl,libgif.$(SO).$(LIBMAJOR)
+        UTIL_SOFLAGS:=-shared -Wl,-soname -Wl,libutil.$(SO).$(LIBMAJOR)
+endif
+
+all: libgif.$(SO) libgif.a libutil.$(SO) libutil.a $(UTILS)
+	true
 
 $(UTILS):: libgif.a libutil.a
 
-libgif.so: $(OBJECTS) $(HEADERS)
-	$(CC) $(CFLAGS) -shared $(LDFLAGS) -Wl,-soname -Wl,libgif.so.$(LIBMAJOR) -o libgif.so $(OBJECTS)
+libgif.$(SO): $(OBJECTS) $(HEADERS) $(UOBJECTS)
+	$(CC) $(CFLAGS) $(LDFLAGS) $(GIF_SOFLAGS) -o libgif.$(SO) $(OBJECTS) $(UOBJECTS)
 
 libgif.a: $(OBJECTS) $(HEADERS)
 	$(AR) rcs libgif.a $(OBJECTS)
 
-libutil.so: $(UOBJECTS) $(UHEADERS)
-	$(CC) $(CFLAGS) -shared $(LDFLAGS) -Wl,-soname -Wl,libutil.so.$(LIBMAJOR) -o libutil.so $(UOBJECTS)
+libutil.$(SO): $(UOBJECTS) $(UHEADERS)
+	$(CC) $(CFLAGS) $(LDFLAGS) $(UTIL_SOFLAGS) -lgif -L. -o libutil.$(SO) $(UOBJECTS)
 
 libutil.a: $(UOBJECTS) $(UHEADERS)
 	$(AR) rcs libutil.a $(UOBJECTS)
 
 clean:
-	rm -f $(UTILS) $(TARGET) libgetarg.a libgif.a libgif.so libutil.a libutil.so *.o
-	rm -f libgif.so.$(LIBMAJOR).$(LIBMINOR).$(LIBPOINT)
-	rm -f libgif.so.$(LIBMAJOR)
+	rm -f $(UTILS) $(TARGET) libgetarg.a libgif.a libgif.$(SO) libutil.a libutil.$(SO) *.o
+	rm -f libgif.$(SO).$(LIBMAJOR).$(LIBMINOR).$(LIBPOINT)
+	rm -f libgif.$(SO).$(LIBMAJOR)
 	rm -fr doc/*.1 *.html doc/staging
 
 check: all
@@ -99,9 +110,9 @@
 install-lib:
 	$(INSTALL) -d "$(DESTDIR)$(LIBDIR)"
 	$(INSTALL) -m 644 libgif.a "$(DESTDIR)$(LIBDIR)/libgif.a"
-	$(INSTALL) -m 755 libgif.so "$(DESTDIR)$(LIBDIR)/libgif.so.$(LIBVER)"
-	ln -sf libgif.so.$(LIBVER) "$(DESTDIR)$(LIBDIR)/libgif.so.$(LIBMAJOR)"
-	ln -sf libgif.so.$(LIBMAJOR) "$(DESTDIR)$(LIBDIR)/libgif.so"
+	$(INSTALL) -m 755 libgif.$(SO) "$(DESTDIR)$(LIBDIR)/libgif.$(SO).$(LIBVER)"
+	ln -sf libgif.$(SO).$(LIBVER) "$(DESTDIR)$(LIBDIR)/libgif.$(SO).$(LIBMAJOR)"
+	ln -sf libgif.$(SO).$(LIBMAJOR) "$(DESTDIR)$(LIBDIR)/libgif.$(SO)"
 install-man:
 	$(INSTALL) -d "$(DESTDIR)$(MANDIR)/man1"
 	$(INSTALL) -m 644 doc/*.1 "$(DESTDIR)$(MANDIR)/man1"
@@ -112,7 +123,7 @@
 	rm -f "$(DESTDIR)$(INCDIR)/gif_lib.h"
 uninstall-lib:
 	cd "$(DESTDIR)$(LIBDIR)" && \
-		rm -f libgif.a libgif.so libgif.so.$(LIBMAJOR) libgif.so.$(LIBVER)
+		rm -f libgif.a libgif.$(SO) libgif.$(SO).$(LIBMAJOR) libgif.$(SO).$(LIBVER)
 uninstall-man:
 	cd "$(DESTDIR)$(MANDIR)/man1" && rm -f $(shell cd doc >/dev/null && echo *.1)
 
EOF

# Thanks to https://682198.bugs.gentoo.org/attachment.cgi?id=609396 via https://bugs.gentoo.org/682198
patch -p1 << 'EOF'
Index: giflib-5.2.1/gif_lib.h
===================================================================
--- giflib-5.2.1.orig/gif_lib.h
+++ giflib-5.2.1/gif_lib.h
@@ -295,6 +295,14 @@ extern void GifDrawBoxedText8x8(SavedIma
                           const char *legend,
                           const int border, const int bg, const int fg);
 
+/******************************************************************************
+ Color table quantization
+******************************************************************************/
+int GifQuantizeBuffer(unsigned int Width, unsigned int Height,
+                   int *ColorMapSize, GifByteType * RedInput,
+                   GifByteType * GreenInput, GifByteType * BlueInput,
+                   GifByteType * OutputBuffer,
+                   GifColorType * OutputColorMap);
 #ifdef __cplusplus
 }
 #endif /* __cplusplus */
EOF

CFLAGS="$(tiger.sh -mcpu -O)"
LDFLAGS=""
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# Note: this makefile seems to misbehave for anything above -j1
make OFLAGS="" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" CC="$CC" PREFIX=/opt/$pkgspec

# Note: no 'make check' available.

make install PREFIX=/opt/$pkgspec

mkdir -p /opt/$pkgspec/lib/pkgconfig
cat > /opt/$pkgspec/lib/pkgconfig/libgif.pc << EOF
prefix=/opt/$pkgspec
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libgif
Description: GIF image codec
Version: $version
Libs: -L\${libdir} -lgif
Cflags: -I\${includedir}
EOF

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
