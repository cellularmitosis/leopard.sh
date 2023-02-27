#!/bin/bash
# based on templates/build-from-source.sh v6

# Install x264 on OS X Leopard / PowerPC.

package=x264
version=ca5408b1
# git clone https://code.videolan.org/videolan/x264.git
upstream=https://code.videolan.org/videolan/x264/-/archive/master/x264-master.tar.bz2
description="H.264/MPEG-4 AVC codec"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

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

CC=gcc-4.9
CXX=g++-4.9

# gcc-4.9: error: unrecognized command line option '-fastf'
sed -i '' -e 's/ -fastf / -ffast-math /' configure

env CC="$CC" \
    CXX="$CXX" \
    /usr/bin/time ./configure --prefix=/opt/$pkgspec \
        --enable-shared

# configure seems to incorrectly detect VSX instructions.
sed -i '' -e 's/ -mvsx / /' config.mak

# cc1: warning: '-mdynamic-no-pic' overrides '-fpic', '-fPIC', '-fpie' or '-fPIE'
sed -i '' -e 's/ -fPIC / /' config.mak

if test -n "$ppc64" ; then
     sed -i '' -e "s/-mcpu=G3/ $(leopard.sh -mcpu) -m64 /" config.mak
     sed -i '' -e "s/-mcpu=G4/ $(leopard.sh -mcpu) -m64 /" config.mak
     sed -i '' -e "s/-mcpu=G5/ $(leopard.sh -mcpu) -m64 /" config.mak
     sed -i '' -e 's/LDFLAGS=/LDFLAGS=-m64 /' config.mak
else
     sed -i '' -e "s/-mcpu=G3/ $(leopard.sh -mcpu) /" config.mak
     sed -i '' -e "s/-mcpu=G4/ $(leopard.sh -mcpu) /" config.mak
     sed -i '' -e "s/-mcpu=G5/ $(leopard.sh -mcpu) /" config.mak
fi

# configure seems to incorrectly detect VSX instructions.
sed -i '' -e 's/#define HAVE_VSX 1/#define HAVE_VSX 0/' config.h

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
