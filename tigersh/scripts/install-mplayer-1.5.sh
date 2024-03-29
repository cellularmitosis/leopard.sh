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

for pair in \
"openssl-1.1.1t$ppc64 ssl" \
"sdl-1.2.15.20220129$ppc64 SDL" \
"libdvdnav-6.1.1$ppc64 dvdnav" \
"libdvdread-6.1.3$ppc64 dvdread" \
"libdvdcss-1.4.3$ppc64 dvdcss" \
"libjpeg-6b$ppc64 jpeg" \
"libpng-1.6.40$ppc64 png" \
"libgif-5.2.1$ppc64 gif" \
"freetype-2.13.0$ppc64 freetype" \
"fontconfig-2.14.1$ppc64 fontconfig" \
"twolame-0.4.0$ppc64 twolame" \
"libogg-1.3.5$ppc64 ogg" \
"libvorbis-1.3.7$ppc64 vorbis" \
"libtheora-1.1.1$ppc64 theora" \
"speex-1.2.1$ppc64 speex" \
"mpg123-1.31.2$ppc64 mpg123" \
"opus-1.1.2$ppc64 opus" \
"libxml2-2.9.12$ppc64 xml2" \
"lame-3.100$ppc64 mp3lame" \
; do
    depspec=$(echo $pair | awk '{print $1}')
    libname=$(echo $pair | awk '{print $2}')
    if ! test -e /opt/$depspec ; then
        tiger.sh $depspec
    fi
    CPPFLAGS="-I/opt/$depspec/include $CPPFLAGS"
    LDFLAGS="-L/opt/$depspec/lib $LDFLAGS"
    LIBS="-l$libname $LIBS"
    PATH="/opt/$depspec/bin:$PATH"
done

# Note: x264 does not run on G3 processors.
if test "$(tiger.sh --cpu)" != "g3" ; then
    for pair in \
    "x264-ca5408b1$ppc64 x264" \
    ; do
        depspec=$(echo $pair | awk '{print $1}')
        libname=$(echo $pair | awk '{print $2}')
        if ! test -e /opt/$depspec ; then
            tiger.sh $depspec
        fi
        CPPFLAGS="-I/opt/$depspec/include $CPPFLAGS"
        LDFLAGS="-L/opt/$depspec/lib $LDFLAGS"
        LIBS="-l$libname $LIBS"
        PATH="/opt/$depspec/bin:$PATH"
    done
fi

dep=macports-legacy-support-20221029$ppc64
if ! test -e /opt/$dep ; then
    tiger.sh $dep
fi
CPPFLAGS="-I/opt/$dep/include/LegacySupport $CPPFLAGS"
LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
LIBS="-lMacportsLegacySupport $LIBS"

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
CC=gcc-4.9
CXX=g++-4.9
OBJC=gcc-4.9

if ! type -a pkg-config >/dev/null 2>&1 ; then
    tiger.sh pkg-config-0.29.2
fi
export PATH="/opt/pkg-config-0.29.2/bin:$PATH"
PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

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
    env CC="$CC" CXX="$CXX" PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
    ./configure --prefix=/opt/$pkgspec \
    --codecsdir="/opt/mplayer-binary-codecs-20041107/lib/codecs" \
    --enable-openssl-nondistributable \
    --enable-macosx-finder \
    --enable-macosx-bundle \
    --extra-cflags="$CPPFLAGS" \
    --extra-ldflags="$LDFLAGS" \
    --extra-libs-mplayer="$LIBS" \
    --extra-libs-mencoder="$LIBS" \
    | tee /tmp/mplayer.log

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
