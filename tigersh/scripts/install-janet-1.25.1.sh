#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install janet on OS X Tiger / PowerPC.

package=janet
version=1.25.1
upstream=https://github.com/janet-lang/janet/archive/refs/tags/v$version.tar.gz

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

# Note: building on G5 fails with:
# ./build/janet tools/patch-header.janet src/include/janet.h src/conf/janetconf.h build/janet.h
# C runtime error at line 388 in file src/core/gc.c: please initialize janet before use
# make: *** [Makefile:181: build/janet.h] Error 1
if test "$(leopard.sh --cpu)" = "g5" ; then
    exit 1
fi

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

# Janet needs thread-local storage.
if ! test -e /opt/gcc-4.9.4 ; then
    tiger.sh gcc-4.9.4
fi
CC=gcc-4.9

if ! test -e /opt/make-4.3 ; then
    tiger.sh make-4.3
fi
export PATH="/opt/make-4.3/bin:$PATH"

if ! test -e /opt/ld64-97.17-tigerbrew ; then
    tiger.sh ld64-97.17-tigerbrew
fi
export PATH="/opt/ld64-97.17-tigerbrew/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

patch -p1 << "EOF"
diff '--color=auto' -urN janet/src/core/ev.c janet.patched/src/core/ev.c
--- janet/src/core/ev.c	2022-03-24 23:47:52.988542000 -0500
+++ janet.patched/src/core/ev.c	2022-03-24 23:38:45.226511000 -0500
@@ -1634,7 +1634,11 @@

 static JanetTimestamp ts_now(void) {
     struct timespec now;
+#if defined(JANET_APPLE) && !defined(MAC_OS_X_VERSION_10_12)
+    janet_gettime(&now);
+#else
     janet_assert(-1 != clock_gettime(CLOCK_MONOTONIC, &now), "failed to get time");
+#endif
     uint64_t res = 1000 * now.tv_sec;
     res += now.tv_nsec / 1000000;
     return res;
EOF

patch -p1 << "EOF"
diff '--color=auto' -urN janet/src/core/util.c janet.patched/src/core/util.c
--- janet/src/core/util.c	2022-03-24 22:02:25.212820000 -0500
+++ janet.patched/src/core/util.c	2022-03-25 00:07:49.583948238 -0500
@@ -851,7 +851,11 @@
        In these cases, use this fallback path for now... */
     int rc;
     int randfd;
-    RETRY_EINTR(randfd, open("/dev/urandom", O_RDONLY | O_CLOEXEC));
+    int flags = O_RDONLY;
+#ifdef O_CLOEXEC
+    flags |= O_CLOEXEC;
+#endif
+    RETRY_EINTR(randfd, open("/dev/urandom", flags));
     if (randfd < 0)
         return -1;
     while (n > 0) {
EOF

patch -p0 << "EOF"
--- src/core/os.c.orig	2022-03-29 23:42:18.000000000 -0500
+++ src/core/os.c	2022-03-30 00:24:07.000000000 -0500
@@ -46,7 +46,10 @@
 #include <io.h>
 #include <process.h>
 #else
+/* spawn.h unavailable on OS X prior to 10.5 */
+#if ! (defined(JANET_APPLE) && !defined(MAC_OS_X_VERSION_10_5))
 #include <spawn.h>
+#endif
 #include <utime.h>
 #include <unistd.h>
 #include <dirent.h>
@@ -960,6 +963,8 @@
     }
 
     /* Posix spawn setup */
+    pid_t pid;
+#ifdef POSIX_SPAWN_RESETIDS
     posix_spawn_file_actions_t actions;
     posix_spawn_file_actions_init(&actions);
     if (pipe_in != JANET_HANDLE_NONE) {
@@ -984,7 +989,6 @@
         posix_spawn_file_actions_addclose(&actions, new_err);
     }
 
-    pid_t pid;
     if (janet_flag_at(flags, 1)) {
         status = posix_spawnp(&pid,
                               child_argv[0], &actions, NULL, cargv,
@@ -996,6 +1000,16 @@
     }
 
     posix_spawn_file_actions_destroy(&actions);
+#else
+    pid = fork();
+    if (pid == 0) {
+        /* This is the child process. */
+        status = execve(child_argv[0], cargv, envp);
+        /* Note: a successful execve does not return.
+           Therefore, continued execution indicates execve has failed. */
+        exit(errno);
+    }
+#endif
 
     if (pipe_in != JANET_HANDLE_NONE) close(pipe_in);
     if (pipe_out != JANET_HANDLE_NONE) close(pipe_out);
EOF

CFLAGS=$(tiger.sh -mcpu -O)

/usr/bin/time make $(tiger.sh -j) \
    PREFIX=/opt/$pkgspec \
    CFLAGS="$CFLAGS" \
    LDFLAGS="" \
    CC="$CC"

if test -n "$TIGERSH_RUN_TESTS" ; then
    make test
fi

make install PREFIX=/opt/$pkgspec

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
