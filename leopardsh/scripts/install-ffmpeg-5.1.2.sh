#!/bin/bash
# based on templates/build-from-source.sh v6

# Install ffmpeg on OS X Leopard / PowerPC.

package=ffmpeg
version=5.1.2
upstream=https://ffmpeg.org/releases/$package-$version.tar.gz
description="Complete solution to record/convert/stream audio and video"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# deps: https://gist.github.com/Danw33/dc507c2a5cbb7026dcfa5b539c530d3c
# deps: https://github.com/razzbee/ffmpeg_installer/blob/master/ffmpeg_installer

for dep in \
    libogg-1.3.5$ppc64 \
    libvorbis-1.3.7$ppc64 \
    opus-1.1.2$ppc64 \
    lame-3.100$ppc64 \
    twolame-0.4.0$ppc64 \
    fdk-aac-2.0.2$ppc64 \
    libtheora-1.1.1$ppc64 \
    x264-ca5408b1$ppc64 \
    sdl2-2.0.3$ppc64 \
    openssl-1.1.1t$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
done
# LIBS="-lbar -lqux"
PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"

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
CC=gcc-4.9
CXX=g++-4.9

# 👇 EDIT HERE:
# if ! which -s gcc-10.3 ; then
#     leopard.sh gcc-10.3.0
# fi

if ! which -s pkg-config ; then
    leopard.sh pkg-config-0.29.2
fi
export PATH="/opt/pkg-config-0.29.2/bin:$PATH"

dep=texi2html-5.0
if ! test -e /opt/$dep ; then
    leopard.sh $dep
    PATH="/opt/$dep/bin:$PATH"
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

patch -p0 << 'EOF'
--- libavcodec/audiotoolboxdec.c	2022-07-22 09:58:38.000000000 -0800
+++ libavcodec/audiotoolboxdec.c.patched	2023-02-26 16:26:25.000000000 -0900
@@ -39,6 +39,9 @@
 #define kAudioFormatEnhancedAC3 'ec-3'
 #endif
 
+#define kAudioFormatMicrosoftGSM 0x6D730031
+#define kAudioFormatiLBC 'ilbc'
+
 typedef struct ATDecodeContext {
     AVClass *av_class;
 
EOF

patch -p0 << 'EOF'
--- libavcodec/audiotoolboxenc.c	2022-07-22 09:58:38.000000000 -0800
+++ libavcodec/audiotoolboxenc.c.patched	2023-02-26 16:27:23.000000000 -0900
@@ -38,6 +38,9 @@
 #include "libavutil/opt.h"
 #include "libavutil/log.h"
 
+#define kAudioFormatMPEG4AAC_ELD 'aace'
+#define kAudioFormatiLBC 'ilbc'
+
 typedef struct ATDecodeContext {
     AVClass *av_class;
     int mode;
EOF

CFLAGS="$(leopard.sh -mcpu) $CFLAGS"
CXXFLAGS="$(leopard.sh -mcpu) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# Note: to help diagnose dependency issues:
#   cat ffbuild/config.log | grep _deps

# Thanks to https://www.linuxfromscratch.org/blfs/view/svn/multimedia/ffmpeg.html
export PKG_CONFIG_PATH
env CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CPPFLAGS="$CPPFLAGS" \
    PKG_CONFIG=/opt/pkg-config-0.29.2/bin/pkg-config \
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
    /usr/bin/time ./configure --prefix=/opt/$pkgspec \
        --cc="$CC" \
        --cxx="$CXX" \
        --enable-gpl \
        --enable-version3 \
        --enable-nonfree \
        --enable-shared \
        --disable-debug \
        --enable-ffplay \
        --enable-openssl \
        --enable-libvorbis \
        --enable-libopus \
        --enable-libmp3lame \
        --enable-libtwolame \
        --enable-libfdk-aac \
        --enable-libtheora \
        --enable-libx264 \

# sed -i '' -e 's/ -O3 / -O1 /' ffbuild/config.mak


        # --enable-libass \
        # --enable-libdrm \
        # --enable-libvpx \
        # --enable-libx265 \

if test -n "$ppc64" ; then
    sed -i '' -e 's/ASFLAGS=/ASFLAGS=-m64 /' ffbuild/config.mak
fi

/usr/bin/time make $(leopard.sh -j) V=1

gcc tools/qt-faststart.c -o tools/qt-faststart

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

make install
cp tools/qt-faststart /opt/$pkgspec/bin/

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi

# ppc64 build failing:
#   ranlib: archive member: libavcodec/libavcodec.a(fft_altivec.o) cputype (18) does not match previous archive members cputype (16777234) (all members must match)
#   ranlib libavcodec/libavcodec.a
#   ranlib: archive member: libavcodec/libavcodec.a(fft_altivec.o) cputype (18) does not match previous archive members cputype (16777234) (all members must match)
#   ranlib: for architecture: ppc64 file: libavcodec/libavcodec.a(fft_vsx.o) has no symbols
#   ranlib: for architecture: ppc file: libavcodec/libavcodec.a(fft_altivec.o) has no symbols
# This was the compilation line for fft_altivec.o:
#   gcc-4.9 -I. -I./ -I/opt/openssl-1.1.1t.ppc64/include -I/opt/sdl2-2.0.3.ppc64/include -I/opt/x264-ca5408b1.ppc64/include -I/opt/libtheora-1.1.1.ppc64/include -I/opt/fdk-aac-2.0.2.ppc64/include -I/opt/twolame-0.4.0.ppc64/include -I/opt/lame-3.100.ppc64/include -I/opt/libvorbis-1.3.7.ppc64/include -I/opt/libogg-1.3.5.ppc64/include  -D_ISOC99_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -DPIC -DZLIB_CONST -force_cpusubtype_ALL -fPIC  -MMD -MF libavcodec/ppc/fft_altivec.d -MT libavcodec/ppc/fft_altivec.o -c -o libavcodec/ppc/fft_altivec.o libavcodec/ppc/fft_altivec.S
# Looks like there is no -m64 flag there.
