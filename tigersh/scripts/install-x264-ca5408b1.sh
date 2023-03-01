#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install x264 on OS X Tiger / PowerPC.

package=x264
# Note: this revision is from before the ppc assembly was updated to use POWER7 VSX instructions.
version=ca5408b1
# git clone https://code.videolan.org/videolan/x264.git
upstream=https://code.videolan.org/videolan/x264/-/archive/master/x264-master.tar.bz2
description="H.264/MPEG-4 AVC codec"

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

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
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
sed -i '' -e 's/ -mdynamic-no-pic / /' config.mak

if test -n "$ppc64" ; then
     sed -i '' -e "s/-mcpu=G3/ $(tiger.sh -mcpu) -m64 /" config.mak
     sed -i '' -e "s/-mcpu=G4/ $(tiger.sh -mcpu) -m64 /" config.mak
     sed -i '' -e "s/-mcpu=G5/ $(tiger.sh -mcpu) -m64 /" config.mak
     sed -i '' -e 's/LDFLAGS=/LDFLAGS=-m64 /' config.mak
else
     sed -i '' -e "s/-mcpu=G3/ $(tiger.sh -mcpu) /" config.mak
     sed -i '' -e "s/-mcpu=G4/ $(tiger.sh -mcpu) /" config.mak
     sed -i '' -e "s/-mcpu=G5/ $(tiger.sh -mcpu) /" config.mak
fi
sed -i '' -e "s/ -O3 / $(leopard.sh -O) /" config.mak

# configure seems to incorrectly detect VSX instructions.
sed -i '' -e 's/#define HAVE_VSX 1/#define HAVE_VSX 0/' config.h

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
