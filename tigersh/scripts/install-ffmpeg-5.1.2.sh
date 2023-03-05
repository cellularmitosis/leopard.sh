#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install ffmpeg on OS X Tiger / PowerPC.

package=ffmpeg
version=5.1.2
upstream=https://ffmpeg.org/releases/$package-$version.tar.gz
description="Complete solution to record/convert/stream audio and video"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Tiger's frameworks aren't 64-bit, so we can't link against CoreFoundation, etc.
#   ld: warning: in /System/Library/Frameworks//CoreFoundation.framework/CoreFoundation, file was built for ppc which is not the architecture being linked (ppc64)
#   strip -x -o ffmpeg ffmpeg_g
if test -n "$ppc64" ; then
    exit 1
fi

for dep in \
    libogg-1.3.5$ppc64 \
    libvorbis-1.3.7$ppc64 \
    opus-1.1.2$ppc64 \
    lame-3.100$ppc64 \
    twolame-0.4.0$ppc64 \
    fdk-aac-2.0.2$ppc64 \
    libtheora-1.1.1$ppc64 \
    openssl-1.1.1t$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
done
# LIBS="-lbar -lqux"
PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"

# Note: x264 does not run on G3 processors.
if test "$(tiger.sh --cpu)" != "g3" ; then
    for dep in \
        x264-ca5408b1$ppc64
    do
        if ! test -e /opt/$dep ; then
            tiger.sh $dep
        fi
        CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
        LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
        PATH="/opt/$dep/bin:$PATH"
        PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
    done
    # LIBS="-lbar -lqux"
    PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"
fi

# Note: sdl2 is unavailable on tiger/ppc64, which means we lose ffplay.
if test -z "$ppc64" ; then
    for dep in \
        sdl2-2.0.3
    do
        if ! test -e /opt/$dep ; then
            tiger.sh $dep
        fi
        CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
        LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
        PATH="/opt/$dep/bin:$PATH"
        PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
    done
    # LIBS="-lbar -lqux"
    PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"
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

# 👇 EDIT HERE:
# if ! type -a gcc-10.3 >/dev/null 2>&1 ; then
#     tiger.sh gcc-10.3
# fi

if ! test -e /opt/ld64-97.17-tigerbrew ; then
    tiger.sh ld64-97.17-tigerbrew
fi
export PATH="/opt/ld64-97.17-tigerbrew/bin:$PATH"
CC='gcc-4.9 -B/opt/ld64-97.17-tigerbrew/bin'
CXX='gxx-4.9 -B/opt/ld64-97.17-tigerbrew/bin'

if ! type -a pkg-config >/dev/null 2>&1 ; then
    tiger.sh pkg-config-0.29.2
fi
export PATH="/opt/pkg-config-0.29.2/bin:$PATH"

dep=texi2html-5.0
if ! test -e /opt/$dep ; then
    tiger.sh $dep
    PATH="/opt/$dep/bin:$PATH"
fi

# + /usr/bin/time make -j1 V=1
# tools/Makefile:28: no file name for `-include'
# ffbuild/common.mak:45: *** missing `endif'.  Stop.
if ! test -e /opt/make-4.3 >/dev/null 2>&1 ; then
    tiger.sh make-4.3
fi
export PATH="/opt/make-4.3/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
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

CFLAGS="$(tiger.sh -mcpu) $CFLAGS"
CXXFLAGS="$(tiger.sh -mcpu) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# Note: to help diagnose dependency issues:
#   cat ffbuild/config.log | grep _deps

if test "$(tiger.sh --cpu)" = "g3" ; then
    altivec="--disable-altivec"
fi

# Note: ffmpeg uses features from AudioToolbox which didnt' exist until Leopard.
#   gcc-4.9 -B/opt/ld64-97.17-tigerbrew/bin -I. -I./ -D_ISOC99_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -DZLIB_CONST -DHAVE_AV_CONFIG_H -DBUILDING_avdevice -mcpu=750    -std=c11 -mdynamic-no-pic -fomit-frame-pointer -pthread -Wdeclaration-after-statement -Wall -Wdisabled-optimization -Wpointer-arith -Wredundant-decls -Wwrite-strings -Wtype-limits -Wundef -Wmissing-prototypes -Wstrict-prototypes -Wempty-body -Wno-parentheses -Wno-switch -Wno-format-zero-length -Wno-pointer-sign -Wno-char-subscripts -O0 -fno-math-errno -fno-signed-zeros -fno-tree-vectorize -Werror=format-security -Werror=implicit-function-declaration -Werror=missing-prototypes -Werror=return-type -Werror=vla -Wformat -fdiagnostics-color=auto -Wno-maybe-uninitialized -I/opt/sdl2-2.0.3/include/SDL2 -I/usr/X11R6/include -D_THREAD_SAFE    -MMD -MF libavdevice/audiotoolbox.d -MT libavdevice/audiotoolbox.o -c -o libavdevice/audiotoolbox.o libavdevice/audiotoolbox.m
#   libavdevice/audiotoolbox.m:40:5: error: unknown type name 'AudioQueueBufferRef'
# So we --disable-audiotoolbox.

# if test "$(tiger.sh --cpu)" = "g3" ; then

# unset PKG_CONFIG_PATH
# env CFLAGS="$CFLAGS" \
#     CXXFLAGS="$CXXFLAGS" \
#     /usr/bin/time ./configure --prefix=/opt/$pkgspec \
#         --cc="$CC" \
#         --cxx="$CXX" \
#         $altivec \
#         --enable-gpl \
#         --enable-version3 \
#         --enable-nonfree \
#         --disable-debug \
#         --disable-audiotoolbox \
#         --enable-ffplay

# # sed -i '' -e 's/ -O3 / -O1 /' ffbuild/config.mak

# else

libx264="--enable-libx264"
if test "$(tiger.sh --cpu)" = "g3" ; then
    libx264="--disable-libx264"
fi

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
        $altivec \
        --enable-gpl \
        --enable-version3 \
        --enable-nonfree \
        --enable-shared \
        --disable-debug \
        --disable-audiotoolbox \
        --enable-ffplay \
        --enable-openssl \
        --enable-libvorbis \
        --enable-libopus \
        --enable-libmp3lame \
        --enable-libtwolame \
        --enable-libfdk-aac \
        --enable-libtheora \
        $libx264 \

# sed -i '' -e 's/ -O3 / -O1 /' ffbuild/config.mak

# fi

        # --enable-libass \
        # --enable-libdrm \
        # --enable-libvpx \
        # --enable-libx265 \

if test -n "$ppc64" ; then
    sed -i '' -e 's/ASFLAGS=/ASFLAGS=-m64 /' ffbuild/config.mak
fi

/usr/bin/time /opt/make-4.3/bin/make $(tiger.sh -j) V=1

gcc tools/qt-faststart.c -o tools/qt-faststart

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

/opt/make-4.3/bin/make install
cp tools/qt-faststart /opt/$pkgspec/bin/

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi


# gcc-4.9 -dynamiclib -Wl,-single_module -Wl,-install_name,/opt/ffmpeg-5.1.2/lib/libavutil.57.dylib,-current_version,57.28.100,-compatibility_version,57 -Llibavcodec -Llibavdevice -Llibavfilter -Llibavformat -Llibavutil -Llibpostproc -Llibswscale -Llibswresample -L/opt/openssl-1.1.1t/lib -L/opt/libogg-1.3.5/lib -L/opt/libvorbis-1.3.7/lib -L/opt/twolame-0.4.0/lib -L/opt/lame-3.100/lib -L/opt/fdk-aac-2.0.2/lib   -Wl,-dynamic,-search_paths_first  -o libavutil/libavutil.57.dylib libavutil/adler32.o libavutil/aes.o libavutil/aes_ctr.o libavutil/audio_fifo.o libavutil/avsscanf.o libavutil/avstring.o libavutil/base64.o libavutil/blowfish.o libavutil/bprint.o libavutil/buffer.o libavutil/camellia.o libavutil/cast5.o libavutil/channel_layout.o libavutil/color_utils.o libavutil/cpu.o libavutil/crc.o libavutil/csp.o libavutil/des.o libavutil/detection_bbox.o libavutil/dict.o libavutil/display.o libavutil/dovi_meta.o libavutil/downmix_info.o libavutil/encryption_info.o libavutil/error.o libavutil/eval.o libavutil/fifo.o libavutil/file.o libavutil/file_open.o libavutil/film_grain_params.o libavutil/fixed_dsp.o libavutil/float_dsp.o libavutil/frame.o libavutil/hash.o libavutil/hdr_dynamic_metadata.o libavutil/hdr_dynamic_vivid_metadata.o libavutil/hmac.o libavutil/hwcontext.o libavutil/hwcontext_stub.o libavutil/imgutils.o libavutil/integer.o libavutil/intmath.o libavutil/lfg.o libavutil/lls.o libavutil/log.o libavutil/log2_tab.o libavutil/lzo.o libavutil/mastering_display_metadata.o libavutil/mathematics.o libavutil/md5.o libavutil/mem.o libavutil/murmur3.o libavutil/opt.o libavutil/parseutils.o libavutil/pixdesc.o libavutil/pixelutils.o libavutil/ppc/cpu.o libavutil/ppc/float_dsp_altivec.o libavutil/ppc/float_dsp_init.o libavutil/random_seed.o libavutil/rational.o libavutil/rc4.o libavutil/reverse.o libavutil/ripemd.o libavutil/samplefmt.o libavutil/sha.o libavutil/sha512.o libavutil/slicethread.o libavutil/spherical.o libavutil/stereo3d.o libavutil/tea.o libavutil/threadmessage.o libavutil/time.o libavutil/timecode.o libavutil/tree.o libavutil/twofish.o libavutil/tx.o libavutil/tx_double.o libavutil/tx_float.o libavutil/tx_int32.o libavutil/utils.o libavutil/uuid.o libavutil/version.o libavutil/video_enc_params.o libavutil/xga_font_data.o libavutil/xtea.o  -pthread -lm -framework CoreFoundation -latomic 
# /usr/bin/ld: -i argument: nstall_name must have a ':' between its symbol names
# collect2: error: ld returned 1 exit status
# make: *** [ffbuild/library.mak:119: libavutil/libavutil.57.dylib] Error 1
#      1163.04 real       950.84 user       178.10 sys


# gcc-4.9 -B/opt/ld64-97.17-tigerbrew/bin -I. -I./ -D_ISOC99_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -DZLIB_CONST -DHAVE_AV_CONFIG_H -DBUILDING_avdevice -mcpu=750    -std=c11 -mdynamic-no-pic -fomit-frame-pointer -pthread -Wdeclaration-after-statement -Wall -Wdisabled-optimization -Wpointer-arith -Wredundant-decls -Wwrite-strings -Wtype-limits -Wundef -Wmissing-prototypes -Wstrict-prototypes -Wempty-body -Wno-parentheses -Wno-switch -Wno-format-zero-length -Wno-pointer-sign -Wno-char-subscripts -O0 -fno-math-errno -fno-signed-zeros -fno-tree-vectorize -Werror=format-security -Werror=implicit-function-declaration -Werror=missing-prototypes -Werror=return-type -Werror=vla -Wformat -fdiagnostics-color=auto -Wno-maybe-uninitialized -I/opt/sdl2-2.0.3/include/SDL2 -I/usr/X11R6/include -D_THREAD_SAFE    -MMD -MF libavdevice/audiotoolbox.d -MT libavdevice/audiotoolbox.o -c -o libavdevice/audiotoolbox.o libavdevice/audiotoolbox.m
# libavdevice/audiotoolbox.m:40:5: error: unknown type name 'AudioQueueBufferRef'
#      AudioQueueBufferRef buffer[2];
#      ^
# libavdevice/audiotoolbox.m:43:5: error: unknown type name 'AudioQueueRef'
#      AudioQueueRef       queue;
#      ^
# libavdevice/audiotoolbox.m: In function 'check_status':
# libavdevice/audiotoolbox.m:53:9: warning: format '%i' expects argument of type 'int', but argument 5 has type 'OSStatus' [-Wformat=]
#          av_log(avctx, AV_LOG_ERROR, "Error: %s (%i)\n", msg, *status);
#          ^
# libavdevice/audiotoolbox.m: At top level:
# libavdevice/audiotoolbox.m:61:41: error: unknown type name 'AudioQueueRef'
#  static void queue_callback(void* atctx, AudioQueueRef inAQ,
#                                          ^
# libavdevice/audiotoolbox.m:62:28: error: unknown type name 'AudioQueueBufferRef'
#                             AudioQueueBufferRef inBuffer)
#                             ^
