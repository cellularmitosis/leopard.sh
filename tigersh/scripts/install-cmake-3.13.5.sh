#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install cmake on OS X Tiger / PowerPC.

package=cmake
version=3.13.5
upstream=https://cmake.org/files/v3.13/cmake-$version.tar.gz
description="Cross platform Make"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gcc-4.9.4 ; then
    tiger.sh gcc-libs-4.9.4
fi

dep=cmake-3.9.6$ppc64
if ! test -e /opt/$dep ; then
    tiger.sh $dep
    PATH="/opt/$dep/bin:$PATH"
fi

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

if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Prior to OS X 10.5, unsetenv returned void.
patch -p1 << 'EOF'
diff -urN cmake-3.13.5.orig/Utilities/cmlibuv/src/unix/core.c cmake-3.13.5/Utilities/cmlibuv/src/unix/core.c
--- cmake-3.13.5.orig/Utilities/cmlibuv/src/unix/core.c	2019-05-14 10:46:01.000000000 -0500
+++ cmake-3.13.5/Utilities/cmlibuv/src/unix/core.c	2023-08-26 12:13:08.000000000 -0500
@@ -57,6 +57,10 @@
 # endif
 #endif
 
+#ifdef __APPLE__
+#include <AvailabilityMacros.h>
+#endif
+
 #if defined(__DragonFly__)      || \
     defined(__FreeBSD__)        || \
     defined(__FreeBSD_kernel__) || \
@@ -1293,8 +1297,13 @@
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

# Prior to OS X 10.5, 'st_birthtimespec' didn't exist in stat.h.
patch -p1 << 'EOF'
diff -urN cmake-3.13.5.orig/Utilities/cmlibuv/src/unix/fs.c cmake-3.13.5/Utilities/cmlibuv/src/unix/fs.c
--- cmake-3.13.5.orig/Utilities/cmlibuv/src/unix/fs.c	2019-05-14 10:46:01.000000000 -0500
+++ cmake-3.13.5/Utilities/cmlibuv/src/unix/fs.c	2023-08-26 13:21:28.000000000 -0500
@@ -991,8 +991,14 @@
   dst->st_mtim.tv_nsec = src->st_mtimespec.tv_nsec;
   dst->st_ctim.tv_sec = src->st_ctimespec.tv_sec;
   dst->st_ctim.tv_nsec = src->st_ctimespec.tv_nsec;
+#if defined(MAC_OS_X_VERSION_10_5)
+  // birthtime didn't exist until OS X 10.5.
   dst->st_birthtim.tv_sec = src->st_birthtimespec.tv_sec;
   dst->st_birthtim.tv_nsec = src->st_birthtimespec.tv_nsec;
+#else
+  dst->st_birthtim.tv_sec = 0;
+  dst->st_birthtim.tv_nsec = 0;
+#endif
   dst->st_flags = src->st_flags;
   dst->st_gen = src->st_gen;
 #elif defined(__ANDROID__)
EOF

# Prior to OS X 10.5, 'TIOCPTYGNAME' didn't exist in ttycom.h.
patch -p1 << 'EOF'
diff -urN cmake-3.13.5.orig/Utilities/cmlibuv/src/unix/tty.c cmake-3.13.5/Utilities/cmlibuv/src/unix/tty.c
--- cmake-3.13.5.orig/Utilities/cmlibuv/src/unix/tty.c	2019-05-14 10:46:01.000000000 -0500
+++ cmake-3.13.5/Utilities/cmlibuv/src/unix/tty.c	2023-08-26 13:34:46.000000000 -0500
@@ -44,7 +44,8 @@
   int dummy;
 
   result = ioctl(fd, TIOCGPTN, &dummy) != 0;
-#elif defined(__APPLE__)
+/* TIOCPTYGNAME wasn't available until OS X 10.5. */
+#elif defined(__APPLE__) && defined(MAC_OS_X_VERSION_10_5)
   char dummy[256];
 
   result = ioctl(fd, TIOCPTYGNAME, &dummy) != 0;
EOF

patch -p1 << 'EOF'
diff -urN cmake-3.13.5.orig/Utilities/cmlibuv/src/unix/darwin-proctitle.c cmake-3.13.5/Utilities/cmlibuv/src/unix/darwin-proctitle.c
--- cmake-3.13.5.orig/Utilities/cmlibuv/src/unix/darwin-proctitle.c	2019-05-14 10:46:01.000000000 -0500
+++ cmake-3.13.5/Utilities/cmlibuv/src/unix/darwin-proctitle.c	2023-08-26 14:02:34.000000000 -0500
@@ -29,7 +29,14 @@
 #include <TargetConditionals.h>
 
 #if !TARGET_OS_IPHONE
+#include <AvailabilityMacros.h>
 # include <CoreFoundation/CoreFoundation.h>
+// On OS X Tiger, we have to avoid some TCP_ macro conflicts.
+#if !defined(MAC_OS_X_VERSION_10_5)
+#undef TCP_NODELAY
+#undef TCP_MAXSEG
+#undef TCP_KEEPALIVE
+#endif
 # include <ApplicationServices/ApplicationServices.h>
 #endif
 
EOF

cmake -DCMAKE_INSTALL_PREFIX=/opt/$pkgspec \
    -DCMAKE_C_COMPILER=gcc-4.9 \
    -DCMAKE_CXX_COMPILER=g++-4.9 \
    -DCMAKE_C_FLAGS="-I/opt/macports-legacy-support-20221029/include/LegacySupport -L/opt/macports-legacy-support-20221029/lib -lMacportsLegacySupport" \
    -DCMAKE_CXX_FLAGS="-I/opt/macports-legacy-support-20221029/include/LegacySupport -L/opt/macports-legacy-support-20221029/lib -lMacportsLegacySupport" \
    .
make
make install

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

# Note: no 'make check' available.

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
