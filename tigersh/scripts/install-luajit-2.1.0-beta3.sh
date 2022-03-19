#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install luajit on OS X Tiger / PowerPC.

package=luajit
version=2.1.0-beta3
upstream=https://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz

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

if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
fi

if ! test -e /opt/ld64-97.17 ; then
    tiger.sh ld64-97.17
fi
export PATH="/opt/ld64-97.17/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# see https://www.freelists.org/post/luajit/LuaJIT-on-OS-X-Leopard-PowerPC,3
patch -p1 << "EOF"
diff -urN LuaJIT-2.1.0-beta3/src/host/buildvm.c LuaJIT-2.1.0-beta3.patched/src/host/buildvm.c
--- LuaJIT-2.1.0-beta3/src/host/buildvm.c	2017-05-01 14:05:00.000000000 -0500
+++ LuaJIT-2.1.0-beta3.patched/src/host/buildvm.c	2022-03-19 00:45:57.000000000 -0500
@@ -113,7 +113,7 @@
       name[0] = name[1] == 'R' ? '_' : '@';  /* Just for _RtlUnwind@16. */
     else
       *p = '\0';
-#elif LJ_TARGET_PPC && !LJ_TARGET_CONSOLE
+#elif LJ_TARGET_PPC && !LJ_TARGET_CONSOLE && !LJ_TARGET_OSX
     /* Keep @plt etc. */
 #else
     *p = '\0';
EOF

/usr/bin/time make $(tiger.sh -j) CC="gcc-4.9 $(tiger.sh -mcpu)" PREFIX=/opt/$pkgspec Q=''

# Note: no 'make check' available.

make install PREFIX=/opt/$pkgspec
cd /opt/$pkgspec/bin
ln -s luajit-$version luajit

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
