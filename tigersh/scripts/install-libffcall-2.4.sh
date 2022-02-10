#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install libffcall on OS X Tiger / PowerPC.

package=libffcall
version=2.4

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
#     tiger.sh gcc-4.2
# fi

# echo -n -e "\033]0;tiger.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = e7ef6e7cab40f6e224a89cc8dec6fc15

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    # Note: sys_icache_invalidate is unavailable on tiger.
    patch -p1 << "EOF"
diff '--color=auto' -urN libffcall-2.4/callback/trampoline_r/trampoline.c libffcall-2.4.patched/callback/trampoline_r/trampoline.c
--- libffcall-2.4/callback/trampoline_r/trampoline.c	2021-03-22 18:32:56.000000000 -0500
+++ libffcall-2.4.patched/callback/trampoline_r/trampoline.c	2022-02-09 00:34:32.590302563 -0600
@@ -160,7 +160,11 @@
 # define WIN32_EXTRA_LEAN
 # include <windows.h>
 #elif defined __APPLE__ && defined __MACH__
+# include <AvailabilityMacros.h>
+#if defined(MAC_OS_X_VERSION_10_5)
+/* OSCacheControl.h was introduced in Leopard. */
 # include <libkern/OSCacheControl.h>
+#endif
 #elif defined _AIX
 # include <sys/cache.h>
 #elif defined __sgi
@@ -1301,8 +1305,8 @@
   HANDLE process = GetCurrentProcess ();
   while (!FlushInstructionCache (process, function_x, TRAMP_CODE_LENGTH))
     ;
-#elif defined __APPLE__ && defined __MACH__
-  /* macOS  */
+#elif defined __APPLE__ && defined __MACH__ && defined MAC_OS_X_VERSION_10_5
+  /* macOS and OS X >= Leopard */
   sys_icache_invalidate (function_x, TRAMP_CODE_LENGTH);
 #elif defined _AIX
   /* AIX.  */
diff '--color=auto' -urN libffcall-2.4/trampoline/trampoline.c libffcall-2.4.patched/trampoline/trampoline.c
--- libffcall-2.4/trampoline/trampoline.c	2021-03-22 18:32:42.000000000 -0500
+++ libffcall-2.4.patched/trampoline/trampoline.c	2022-02-09 00:25:54.879542692 -0600
@@ -160,7 +160,11 @@
 # define WIN32_EXTRA_LEAN
 # include <windows.h>
 #elif defined __APPLE__ && defined __MACH__
+# include <AvailabilityMacros.h>
+#if defined(MAC_OS_X_VERSION_10_5)
+/* OSCacheControl.h was introduced in Leopard. */
 # include <libkern/OSCacheControl.h>
+#endif
 #elif defined _AIX
 # include <sys/cache.h>
 #elif defined __sgi
@@ -1550,8 +1554,8 @@
   HANDLE process = GetCurrentProcess ();
   while (!FlushInstructionCache (process, function_x, TRAMP_CODE_LENGTH))
     ;
-#elif defined __APPLE__ && defined __MACH__
-  /* macOS  */
+#elif defined __APPLE__ && defined __MACH__ && defined MAC_OS_X_VERSION_10_5
+  /* macOS and OS X >= Leopard */
   sys_icache_invalidate (function_x, TRAMP_CODE_LENGTH);
 #elif defined _AIX
   /* AIX.  */
EOF

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    # export CC=gcc-4.2 CXX=g++-4.2

    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(tiger.sh -mcpu -O)"
        CXXFLAGS="-m64 $(tiger.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        cpu=$(tiger.sh --cpu)
        if test "$cpu" = "g3" ; then
            # make check fails with "illegal instruction"
            exit 1
        elif test "$cpu" = "g4" ; then
            # fails to build, try default flags.
            CFLAGS=-O2
            CXXFLAGS=-O2
        elif test "$cpu" = "g4e" ; then
            # works.
            CFLAGS=$(tiger.sh -m32 -mcpu -O)
            CXXFLAGS=$(tiger.sh -m32 -mcpu -O)
        elif test "$cpu" = "g5" ; then
            # fails some tests, try default flags.
            CFLAGS=-O2
            CXXFLAGS=-O2
        fi
    fi
    export CFLAGS CXXFLAGS

    ./configure -C --prefix=/opt/$pkgspec \
        --with-threads=posix

    make $(tiger.sh -j) V=1

    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi

    make install

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi

# fails on tiger with:
# cd trampoline && make all
# /bin/sh ../libtool --mode=compile gcc -std=gnu99 -I. -I. -I.. -I../gnulib-lib -I./../gnulib-lib  -mcpu=7450 -O2 -c ./trampoline.c
# libtool: compile:  gcc -std=gnu99 -I. -I. -I.. -I../gnulib-lib -I./../gnulib-lib -mcpu=7450 -O2 -c ./trampoline.c  -fno-common -DPIC -o .libs/trampoline.o
# ./trampoline.c:163:37: error: libkern/OSCacheControl.h: No such file or directory
# ./trampoline.c: In function 'alloc_trampoline':
# ./trampoline.c:1555: warning: implicit declaration of function 'sys_icache_invalidate'
# make[1]: *** [trampoline.lo] Error 1
# make: *** [all-subdirs] Error 2

# hmm, /usr/include/libkern/OSCacheControl.h is present on leopard but not on tiger :(
# OSCacheControl.h is needed to call sys_icache_invalidate
# see https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/sys_icache_invalidate.3.html

# it sounds like some processors don't support flushing icache, and in those cases
# libffcall will simply write a bunch of data into memory to fill the cache.
# perhaps I can simply configure libffcall to do this on tiger?

# see also https://stackoverflow.com/questions/58426975/how-to-invalidate-or-flush-a-range-of-cpu-cache-in-powerpc-architecture

# see also https://www.ibm.com/docs/en/aix/7.1?topic=set-icbi-instruction-cache-block-invalidate-instruction
# see also https://www.ibm.com/docs/en/aix/7.2?topic=set-dcbf-data-cache-block-flush-instruction


# this patch passes tests on tiger g4, but fails on g5 (32-bit):

# libtool: link: g++ -m32 -mcpu=970 -O2 -x none minitests-c++.o -o .libs/minitests-c++ -Wl,-bind_at_load  ./.libs/libcallback.dylib
# ./test1
# Works, test1 passed.
# ./minitests > minitests.out
# make[1]: *** [check] Error 132
# make: *** [check] Error 2

# also fails on tiger g3:
# libtool: link: g++ -mcpu=750 -Os -x none test2-c++.o -o .libs/test2-c++ -Wl,-bind_at_load  ./.libs/libtrampoline.dylib
# ./test1
# make[1]: *** [check] Illegal instruction
# make: *** [check] Error 2

# fails to build on graphite? (7400 g4)
# libtool: link: rm -fr .libs/libtrampoline.lax .libs/libtrampoline.lax
# libtool: link: ( cd ".libs" && rm -f "libtrampoline.la" && ln -s "../libtrampoline.la" "libtrampoline.la" )
# make: *** [all-subdirs] Error 2

# the only difference would be '-mcpu=7400 -Os' vs '-mcpu=7450 -O2'

# tiger ppc64 fails to build:
# /bin/sh ../libtool --mode=compile gcc -std=gnu99 -x none -c avcall-powerpc64.s
# libtool: compile:  gcc -std=gnu99 -x none -c avcall-powerpc64.s  -fno-common -DPIC -o .libs/avcall-powerpc64.o
# avcall-powerpc64.c:2:unknown .machine argument: power4
# avcall-powerpc64.c:4:Expected comma after segment-name
# avcall-powerpc64.c:4:Rest of line ignored. 1st junk character valued 32 ( ).
# avcall-powerpc64.c:10:Invalid mnemonic 'tocbase,0'
# avcall-powerpc64.c:11:Unknown pseudo-op: .previous
# avcall-powerpc64.c:12:Unknown pseudo-op: .type
# avcall-powerpc64.c:12:Rest of line ignored. 1st junk character valued 97 (a).
# avcall-powerpc64.c:12:Invalid mnemonic 'function'
# avcall-powerpc64.c:14:Parameter syntax error (parameter 1)
# avcall-powerpc64.c:15:Parameter syntax error (parameter 1)
# avcall-powerpc64.c:16:Parameter syntax error (parameter 1)
# ...
# avcall-powerpc64.c:49:Parameter syntax error
# avcall-powerpc64.c:51:Parameter syntax error
# avcall-powerpc64.c:53:Parameter syntax error
# ...
# avcall-powerpc64.c:203:Unknown pseudo-op: .size
# avcall-powerpc64.c:203:Rest of line ignored. 1st junk character valued 97 (a).
# make[1]: *** [avcall-powerpc64.lo] Error 1
# make: *** [all-subdirs] Error 2
