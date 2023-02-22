#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install mplayer on OS X Tiger / PowerPC.

package=mplayer
version=1.5
upstream=https://mplayerhq.hu/MPlayer/releases/MPlayer-$version.tar.gz
description="Movie player for Unix-like systems"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/mplayer-binary-codecs-20041107 ; then
    tiger.sh mplayer-binary-codecs-20041107
fi

if ! test -e /opt/gcc-4.9.4 ; then
    tiger.sh gcc-libs-4.9.4
fi

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

# MPlayer 1.5's Makefile causes:
#   make: *** virtual memory exhausted.  Stop.
# Looks like make 4.3 works.
if ! test -e /opt/make-4.3 ; then
    tiger.sh make-4.3
fi
export PATH="/opt/make-4.3/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CC=gcc-4.9
CXX=g++-4.9

# The build fails due to:
#In file included from stream/vcd_read_darwin.h:32:0,
#                 from stream/stream_vcd.c:46:
#                 /System/Library/Frameworks/IOKit.framework/Headers/storage/IOCDTypes.h:488:9: error: too many #pragma options align=reset
#                  #pragma options align=reset              /* (reset to default struct packing) */
#
# Tiger's IOCDTypes.h line 488 has:
#   #pragma options align=reset              /* (reset to default struct packing) */
#
# Leopard's IOCDTypes.h has:
#   #pragma pack(pop)                        /* (reset to default struct packing) */
#
# The lazy thing to do is temporarily patch IOCDTypes.h, then restore it after the build.
cd /System/Library/Frameworks/IOKit.framework/Headers/storage/
if ! test -e IOCDTypes.h.orig && grep -q -e '#pragma options align=reset' IOCDTypes.h ; then
    sudo mv IOCDTypes.h IOCDTypes.h.orig
    sudo cp IOCDTypes.h.orig IOCDTypes.h
    sudo sed -i '' -e 's/#pragma options align=reset/#pragma pack(pop)/' IOCDTypes.h 
fi
cd -

/usr/bin/time \
    env CC="$CC" CXX="$CXX" \
    ./configure --prefix=/opt/$pkgspec \
    --codecsdir="/opt/mplayer-binary-codecs-20041107/lib/codecs" \
    --enable-macosx-finder

# The build fails with:
#  libvo/osx_objc_common.m: In function '-[MPCommonOpenGLView preinit]':
#  libvo/osx_objc_common.m:163:2: error: unknown type name 'GLint'
#    GLint swapInterval = 1;
#    ^
# For whatever reason, it looks like <OpenGL/gl.h> isn't getting included.
# The easy thing to do is just replace this single instance of 'GLint' with 'long'.
sed -i '' -e 's/GLint/long/g' libvo/osx_objc_common.m

/usr/bin/time make $(tiger.sh -j) V=1

# Restore IOCDTypes.h
cd /System/Library/Frameworks/IOKit.framework/Headers/storage/
if test -e IOCDTypes.h.orig ; then
    sudo rm -f IOCDTypes.h
    sudo mv IOCDTypes.h.orig IOCDTypes.h
fi
cd -

# Note: no 'make check' available.

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
