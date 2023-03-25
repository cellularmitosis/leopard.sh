#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install janet on OS X Tiger / PowerPC.

package=janet
version=1.27.0
upstream=https://github.com/janet-lang/janet/archive/refs/tags/v$version.tar.gz

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

dep=macports-legacy-support-20221029$ppc64
if ! test -e /opt/$dep ; then
    tiger.sh $dep
fi
CPPFLAGS="-I/opt/$dep/include/LegacySupport $CPPFLAGS"
LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
PATH="/opt/$dep/bin:$PATH"
LIBS="-lMacportsLegacySupport"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if test -z "$ppc64" -a "$(tiger.sh --cpu)" = "g5" ; then
    # janet fails to build on G5's:
    #   ./build/janet tools/patch-header.janet src/include/janet.h src/conf/janetconf.h build/janet.h
    #   make: *** [Makefile:188: build/janet.h] Bus error

    # So we instead install the g4e binpkg in that case.
    if tiger.sh --install-binpkg $pkgspec tiger.g4e ; then
        exit 0
    fi
else
    if tiger.sh --install-binpkg $pkgspec ; then
        exit 0
    fi
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

# janet fails to build on G5's:
#   ./build/janet tools/patch-header.janet src/include/janet.h src/conf/janetconf.h build/janet.h
#   make: *** [Makefile:188: build/janet.h] Bus error
if test "$(tiger.sh --cpu)" = "g5" ; then
    exit 1
fi

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

# Janet needs thread-local storage.
if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
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

sed -i '' -e "s|COMMON_CFLAGS:=|COMMON_CFLAGS:= $CPPFLAGS |" Makefile
sed -i '' -e "s|CLIBS=|CLIBS= $LDFLAGS $LIBS |" Makefile

CFLAGS="$(tiger.sh -mcpu -O)"

/usr/bin/time make $(tiger.sh -j) \
    PREFIX=/opt/$pkgspec \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CC="$CC"

if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
    make test
    # Starting suite 9...
    # hello
    # error: bad slot #0, expected string|symbol|keyword|buffer, got nil
    #   in string/trim [src/core/string.c] on line 577
    #   in _while [test/suite0009.janet] on line 33, column 28
    #   in _thunk [test/suite0009.janet] (tailcall) on line 28, column 1
    # make: *** [Makefile:228: test] Error 1
fi

make install PREFIX=/opt/$pkgspec

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
