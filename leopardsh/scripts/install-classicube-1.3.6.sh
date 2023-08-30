#!/bin/bash
# based on templates/build-from-source.sh v6

# Install ClassiCube on OS X Leopard / PowerPC.

package=classicube
version=1.3.6
upstream=https://github.com/UnknownShadow200/ClassiCube/archive/refs/tags/$version.tar.gz
description="Minecraft clone written in C"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

dep=curl-7.87.0
if ! test -e /opt/$dep ; then
    leopard.sh $dep
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

CC=gcc

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Use our libcurl.
# Thanks to https://github.com/UnknownShadow200/ClassiCube/issues/868#issuecomment-1575051204
sed -i '' -e 's|curlLib = String_FromConst("libcurl.4.dylib");|curlLib = String_FromConst("/opt/curl-7.87.0/lib/libcurl.4.dylib");|' src/Http_Worker.c
sed -i '' -e 's|curlLib = String_FromConst("libcurl.dylib");|curlLib = String_FromConst("/opt/curl-7.87.0/lib/libcurl.dylib");|' src/Http_Worker.c

# Start by mimicing upstream's CFLAGS and LDFLAGS:
CFLAGS="$CFLAGS -fno-math-errno"
LDFLAGS="$LDFLAGS -framework Carbon -framework AGL -framework OpenGL -framework IOKit"

# OpenAL seems to be missing.
LDFLAGS="$LDFLAGS -framework OpenAL"

# Add our optimization / arch flags:
CFLAGS="$CFLAGS $(leopard.sh -mcpu -O)"
if test -n "$ppc64" ; then
    CFLAGS="$CFLAGS -m64"
    LDFLAGS="$LDFLAGS -m64"
fi

# Use our libcurl.
CFLAGS="$CFLAGS -I/opt/curl-7.87.0/include"
LDFLAGS="$LDFLAGS -L/opt/curl-7.87.0/lib -lcurl"

# Target OpenGL 1.1
make $(leopard.sh -j) CC="$CC" CFLAGS="$CFLAGS -DCC_BUILD_GL11" LDFLAGS="$LDFLAGS"
mv ClassiCube ClassiCube-OpenGL1.1

# Target OpenGL 1.5
make clean || true
make $(leopard.sh -j) CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"

# Note: no 'make check' available.

mkdir -p /opt/$pkgspec/bin
cp ClassiCube ClassiCube-OpenGL1.1 /opt/$pkgspec/bin/
cp -r doc /opt/$pkgspec/

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
