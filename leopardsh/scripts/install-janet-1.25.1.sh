#!/bin/bash
# based on templates/build-from-source.sh v6

# Install janet on OS X Leopard / PowerPC.

package=janet
version=1.25.1
upstream=https://github.com/janet-lang/janet/archive/refs/tags/v$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gcc-4.9.4 ; then
    leopard.sh gcc-libs-4.9.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if test -z "$ppc64" -a "$(leopard.sh --cpu)" = "g5" ; then
    # janet fails during a 32-bit build on a G5 machine,
    # so we instead install the g4e binpkg in that case.
    if leopard.sh --install-binpkg $pkgspec leopard.g4e ; then
        exit 0
    fi
else
    if leopard.sh --install-binpkg $pkgspec ; then
        exit 0
    fi
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

# Note: building on G5 fails with:
# ./build/janet tools/patch-header.janet src/include/janet.h src/conf/janetconf.h build/janet.h
# C runtime error at line 388 in file src/core/gc.c: please initialize janet before use
# make: *** [Makefile:181: build/janet.h] Error 1
if test "$(tiger.sh --cpu)" = "g5" ; then
    exit 1
fi

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

# Janet needs thread-local storage.
if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

CC=gcc-4.9

if ! test -e /opt/make-4.3 ; then
    leopard.sh make-4.3
fi
export PATH="/opt/make-4.3/bin:$PATH"

if ! test -e /opt/ld64-97.17-tigerbrew ; then
    leopard.sh ld64-97.17-tigerbrew
fi
export PATH="/opt/ld64-97.17-tigerbrew/bin:$PATH"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
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


CFLAGS=$(leopard.sh -mcpu -O)

/usr/bin/time make $(leopard.sh -j) \
    PREFIX=/opt/$pkgspec \
    CFLAGS="$CFLAGS" \
    LDFLAGS="" \
    CC="$CC"

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make test
fi

make install PREFIX=/opt/$pkgspec

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
