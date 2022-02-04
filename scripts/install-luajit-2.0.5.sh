#!/bin/bash

# Install luajit on OS X Leopard / PowerPC.

package=luajit
version=2.0.5

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: luajit needs at least GCC 4.3:
# lj_arch.h:395:2: error: #error "Need at least GCC 4.3 or newer"
if ! test -e /opt/gcc-4.9.4$ppc64 ; then
    leopard.sh gcc-4.9.4$ppc64
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(hostname -s))\007

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://luajit.org/download
    tarball=LuaJIT-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd LuaJIT-$version
    patch << 'EOF'
--- Makefile	2022-01-18 02:33:49.000000000 -0600
+++ Makefile.new	2022-01-18 02:34:08.000000000 -0600
@@ -25,7 +25,7 @@
 # Change the installation path as needed. This automatically adjusts
 # the paths in src/luaconf.h, too. Note: PREFIX must be an absolute path!
 #
-export PREFIX= /usr/local
+export PREFIX= /opt/luajit-2.1.0-beta3
 export MULTILIB= lib
 ##############################################################################
EOF
    PATH="/opt/gcc-4.9.4$ppc64/bin:$PATH" make $(leopard.sh -j)
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi
