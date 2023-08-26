#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install libuv on OS X Tiger / PowerPC.

package=libuv
version=1.44.2
upstream=https://github.com/libuv/libuv/archive/refs/tags/v$version.tar.gz
description="Cross-platform asychronous I/O"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

dep=macports-legacy-support-20221029$ppc64
if ! test -e /opt/$dep ; then
    tiger.sh $dep
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

if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.2
fi
CC=gcc-4.2
CXX=g++-4.2

for dep in autoconf-2.71 autogen-5.18.16 automake-1.16.5 libtool-2.4.6 ; do
    tiger.sh $dep
    PATH="/opt/$dep/bin:$PATH"
done

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

LIBTOOLIZE=libtoolize ./autogen.sh

# Many thanks to the MacPorts team!
for pair in \
    "-p0 patch-libuv-legacy.diff" \
    "-p0 patch-libuv-unix-core-close-nocancel.diff" \
    "-p0 patch-no-libutil-on-Tiger.diff" \
; do
    plevel=$(echo $pair | cut -d' ' -f1)
    pfile=$(echo $pair | cut -d' ' -f2)
    url=https://raw.githubusercontent.com/macports/macports-ports/master/devel/libuv/files/$pfile
    curl --fail --silent --show-error --location --remote-name $url
    patch $plevel < $pfile
done

patch -p1 << 'EOF'
diff -urN libuv-1.44.2.orig/src/unix/core.c libuv-1.44.2/src/unix/core.c
--- libuv-1.44.2.orig/src/unix/core.c	2023-08-26 16:50:17.000000000 -0500
+++ libuv-1.44.2/src/unix/core.c	2023-08-26 16:55:20.000000000 -0500
@@ -51,6 +51,10 @@
 #endif
 
 #if defined(__APPLE__)
+#include <AvailabilityMacros.h>
+#endif
+
+#if defined(__APPLE__)
 # include <sys/filio.h>
 # endif /* defined(__APPLE__) */
 
@@ -1375,8 +1379,13 @@
   if (name == NULL)
     return UV_EINVAL;
 
+#if defined(__APPLE__) && !defined(MAC_OS_X_VERSION_10_5)
+  // Prior to OS X 10.5, unsetenv returned void.
+  unsetenv(name);
+#else
   if (unsetenv(name) != 0)
     return UV__ERR(errno);
+#endif
 
   return 0;
 }
EOF

CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(tiger.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

CPPFLAGS="-I/opt/macports-legacy-support-20221029$ppc64/include/LegacySupport $CPPFLAGS"
LDFLAGS="-L/opt/macports-legacy-support-20221029$ppc64/lib $LDFLAGS"
LIBS="-lMacportsLegacySupport $LIBS"

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    CPPFLAGS="$CPPFLAGS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    LIBS="$LIBS" \
    CC="$CC" \
    CXX="$CXX"

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
