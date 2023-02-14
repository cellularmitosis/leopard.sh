#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install QuickJS on OS X Tiger / PowerPC.

package=quickjs
version=20210327
upstream=https://bellard.org/quickjs/quickjs-2021-03-27.tar.xz
description="A small and embeddable ES2020 Javascript engine"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
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

CC=gcc-4.9

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

patch -p1 << 'EOF'
--- quickjs-2021-03-27/Makefile	2021-03-27 05:00:32.000000000 -0500
+++ quickjs-2021-03-27.patched/Makefile	2023-02-13 19:59:21.000000000 -0600
@@ -28,7 +28,7 @@
 # Windows cross compilation from Linux
 #CONFIG_WIN32=y
 # use link time optimization (smaller and faster executables but slower build)
-CONFIG_LTO=y
+#CONFIG_LTO=y
 # consider warnings as errors (for development)
 #CONFIG_WERROR=y
 # force 32 bit build for some utilities
@@ -36,7 +36,7 @@
 
 ifdef CONFIG_DARWIN
 # use clang instead of gcc
-CONFIG_CLANG=y
+#CONFIG_CLANG=y
 CONFIG_DEFAULT_AR=y
 endif
 
@@ -87,7 +87,7 @@
 else
   HOST_CC=gcc
   CC=$(CROSS_PREFIX)gcc
-  CFLAGS=-g -Wall -MMD -MF $(OBJDIR)/$(@F).d
+  CFLAGS=$(CFLAGS_USER) -Wall -MMD -MF $(OBJDIR)/$(@F).d
   CFLAGS += -Wno-array-bounds -Wno-format-truncation
   ifdef CONFIG_LTO
     AR=$(CROSS_PREFIX)gcc-ar
@@ -110,7 +110,7 @@
 CFLAGS+=$(DEFINES)
 CFLAGS_DEBUG=$(CFLAGS) -O0
 CFLAGS_SMALL=$(CFLAGS) -Os
-CFLAGS_OPT=$(CFLAGS) -O2
+CFLAGS_OPT=$(CFLAGS)
 CFLAGS_NOLTO:=$(CFLAGS_OPT)
 LDFLAGS=-g
 ifdef CONFIG_LTO
EOF

if test -n "$ppc64" ; then
    patch -p1 << 'EOF'
--- quickjs-2021-03-27/qjsc.c	2021-03-27 05:00:32.000000000 -0500
+++ quickjs-2021-03-27.patched/qjsc.c	2023-02-13 20:19:07.000000000 -0600
@@ -452,6 +452,8 @@
     *arg++ = "-lm";
     *arg++ = "-ldl";
     *arg++ = "-lpthread";
+    *arg++ = "-latomic";
+    *arg++ = "-m64";
     *arg = NULL;
     
     if (verbose) {
EOF
else
    patch -p1 << 'EOF'
--- quickjs-2021-03-27/qjsc.c	2021-03-27 05:00:32.000000000 -0500
+++ quickjs-2021-03-27.patched/qjsc.c	2023-02-13 19:20:14.000000000 -0600
@@ -452,6 +452,7 @@
     *arg++ = "-lm";
     *arg++ = "-ldl";
     *arg++ = "-lpthread";
+    *arg++ = "-latomic";
     *arg = NULL;
     
     if (verbose) {
EOF
fi

patch -p1 << 'EOF'
--- quickjs-2021-03-27/quickjs-libc.c	2021-03-27 05:00:32.000000000 -0500
+++ quickjs-2021-03-27.patched/quickjs-libc.c	2023-02-13 19:15:16.000000000 -0600
@@ -1964,12 +1964,27 @@
 }
 
 #if defined(__linux__) || defined(__APPLE__)
+/* clock_gettime() wasn't available on Mac until 10.12. */
+#if defined(__APPLE__) && !defined(MAC_OS_X_VERSION_10_12)
+#include <mach/clock.h>
+#include <mach/mach.h>
+static int64_t get_time_ms(void)
+{
+    clock_serv_t cclock;
+    mach_timespec_t mts;
+    host_get_clock_service(mach_host_self(), CALENDAR_CLOCK, &cclock);
+    clock_get_time(cclock, &mts);
+    mach_port_deallocate(mach_task_self(), cclock);
+    return (uint64_t)mts.tv_sec * 1000 + (mts.tv_nsec / 1000000);
+}
+#else
 static int64_t get_time_ms(void)
 {
     struct timespec ts;
     clock_gettime(CLOCK_MONOTONIC, &ts);
     return (uint64_t)ts.tv_sec * 1000 + (ts.tv_nsec / 1000000);
 }
+#endif
 #else
 /* more portable, but does not work if the date is updated */
 static int64_t get_time_ms(void)
EOF

patch -p1 << 'EOF'
--- quickjs-2021-03-27/quickjs.c	2021-03-27 05:00:32.000000000 -0500
+++ quickjs-2021-03-27.patched/quickjs.c	2023-02-13 19:10:17.000000000 -0600
@@ -53789,6 +53789,12 @@
 static struct list_head js_atomics_waiter_list =
     LIST_HEAD_INIT(js_atomics_waiter_list);
 
+/* clock_gettime() wasn't available on Mac until 10.12. */
+#if defined(__APPLE__) && !defined(MAC_OS_X_VERSION_10_12)
+#include <mach/clock.h>
+#include <mach/mach.h>
+#endif
+
 static JSValue js_atomics_wait(JSContext *ctx,
                                JSValueConst this_obj,
                                int argc, JSValueConst *argv)
@@ -53852,6 +53858,16 @@
         pthread_cond_wait(&waiter->cond, &js_atomics_mutex);
         ret = 0;
     } else {
+/* clock_gettime() wasn't available on Mac until 10.12. */
+#if defined(__APPLE__) && !defined(MAC_OS_X_VERSION_10_12)
+        clock_serv_t cclock;
+        mach_timespec_t mts;
+        host_get_clock_service(mach_host_self(), CALENDAR_CLOCK, &cclock);
+        clock_get_time(cclock, &mts);
+        mach_port_deallocate(mach_task_self(), cclock);
+        ts.tv_sec = mts.tv_sec;
+        ts.tv_nsec = mts.tv_nsec;
+#else
         /* XXX: use clock monotonic */
         clock_gettime(CLOCK_REALTIME, &ts);
         ts.tv_sec += timeout / 1000;
@@ -53860,6 +53876,7 @@
             ts.tv_nsec -= 1000000000;
             ts.tv_sec++;
         }
+#endif
         ret = pthread_cond_timedwait(&waiter->cond, &js_atomics_mutex,
                                      &ts);
     }
EOF

patch -p1 << 'EOF'
--- quickjs-2021-03-27/run-test262.c	2021-03-27 05:00:32.000000000 -0500
+++ quickjs-2021-03-27.patched/run-test262.c	2023-02-13 19:16:24.000000000 -0600
@@ -648,12 +648,27 @@
     return JS_UNDEFINED;
 }
 
+/* clock_gettime() wasn't available on Mac until 10.12. */
+#if defined(__APPLE__) && !defined(MAC_OS_X_VERSION_10_12)
+#include <mach/clock.h>
+#include <mach/mach.h>
+static int64_t get_clock_ms(void)
+{
+    clock_serv_t cclock;
+    mach_timespec_t mts;
+    host_get_clock_service(mach_host_self(), CALENDAR_CLOCK, &cclock);
+    clock_get_time(cclock, &mts);
+    mach_port_deallocate(mach_task_self(), cclock);
+    return (uint64_t)mts.tv_sec * 1000 + (mts.tv_nsec / 1000000);
+}
+#else
 static int64_t get_clock_ms(void)
 {
     struct timespec ts;
     clock_gettime(CLOCK_MONOTONIC, &ts);
     return (uint64_t)ts.tv_sec * 1000 + (ts.tv_nsec / 1000000);
 }
+#endif
 
 static JSValue js_agent_monotonicNow(JSContext *ctx, JSValue this_val,
                                      int argc, JSValue *argv)
EOF

if test -n "$ppc64" ; then
    # Note: the ppc64 build of qjsc seems to segfault:
    #   gcc-4.9 -m64  -o qjsc .obj/qjsc.o .obj/quickjs.o .obj/libregexp.o .obj/libunicode.o .obj/cutils.o .obj/quickjs-libc.o .obj/libbf.o -lm -ldl -lpthread -latomic
    #   ./qjsc -c -o repl.c -m repl.js
    #   make: *** [repl.c] Segmentation fault
    #   make: *** Deleting file `repl.c'
    exit 1
fi

/usr/bin/time make \
    prefix=/opt/$pkgspec \
    HOST_LIBS="-lm -ldl -lpthread -latomic" \
    EXTRA_LIBS="-latomic" \
    LDEXPORT="" \
    CFLAGS_USER="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CC="$CC" \
    install

cp -rp doc /opt/$pkgspec/

if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
    make \
        prefix=/opt/$pkgspec \
        HOST_LIBS="-lm -ldl -lpthread -latomic" \
        EXTRA_LIBS="-latomic" \
        LDEXPORT="" \
        CFLAGS_USER="$CFLAGS" \
        LDFLAGS="$LDFLAGS" \
        CC="$CC" \
        test
fi

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
