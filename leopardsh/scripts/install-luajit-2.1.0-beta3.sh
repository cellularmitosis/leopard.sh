#!/bin/bash
# based on templates/build-from-source.sh v6

# Install luajit on OS X Leopard / PowerPC.

package=luajit
version=2.1.0-beta3
upstream=https://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz

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

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
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

/usr/bin/time make $(leopard.sh -j) \
    CC="gcc-4.9 $(leopard.sh -mcpu)" \
    PREFIX=/opt/$pkgspec \
    Q=''

# Note: no 'make check' available.

make install PREFIX=/opt/$pkgspec
cd /opt/$pkgspec/bin
ln -s luajit-$version luajit

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
