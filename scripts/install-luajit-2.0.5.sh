#!/bin/bash

# Install luajit on OS X Leopard / PowerPC.

package=luajit
version=2.0.5

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

# if ! which -s xz; then
#     leopard.sh xz-5.2.5
# fi

if ! test -e /opt/gcc-4.9.4; then
    leopard.sh gcc-4.9.4
fi

# if ! test -e /opt/libiconv-1.16; then
#     leopard.sh libiconv-1.16
# fi

# if ! test -e /opt/expat-2.4.3; then
#     leopard.sh expat-2.4.3
# fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://luajit.org/download
    tarball=LuaJIT-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
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
    PATH="/opt/gcc-4.9.4/bin:$PATH" make $(leopard.sh -j)
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/

# Note: luajit needs at least GCC 4.3:
# lj_arch.h:395:2: error: #error "Need at least GCC 4.3 or newer"
