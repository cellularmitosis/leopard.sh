#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install SDL 1.2 on OS X Tiger / PowerPC.

package=sdl
version=1.2.15.20220129
upstream=https://github.com/libsdl-org/SDL-1.2/archive/707e2cc25904bd4ea7ca94f45632e02d7dbee14c.tar.gz

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

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Note: we have to do a bit of flag hackery here to avoid the dylib reporting the wrong arch:
#   Non-fat file: lib/libSDL-1.2.0.dylib is architecture: ppc
CC="gcc $(tiger.sh -mcpu -O)"

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
    CC="$CC -m64"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-oss \
    --disable-alsa \
    --disable-esd \
    --disable-sndio \
    --disable-pulseaudio \
    --disable-nas \
    --disable-video-photon \
    --disable-video-fbcon \
    --disable-video-directfb \
    --disable-video-ps2gs \
    --disable-video-ps3 \
    --disable-video-svga \
    --disable-video-vgl \
    --disable-video-wscons \
    --disable-input-tslib \
    --disable-video-grop \
    --disable-directx \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CC="$CC"

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

# build fails on tiger pp64:
# libtool: compile:  gcc -m64 -mcpu=970 -O2 -I./include -D_GNU_SOURCE=1 -DTARGET_API_MAC_CARBON -DTARGET_API_MAC_OSX -fvisibility=hidden -I/usr/X11R6/include -DXTHREADS -D_THREAD_SAFE -faltivec -force_cpusubtype_ALL -fpascal-strings -Wall -c ./src/audio/macosx/SDL_coreaudio.c  -fno-common -DPIC -o build/.libs/SDL_coreaudio.o
# In file included from /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/DriverServices.h:32,
#                  from /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/CarbonCore.h:125,
#                  from /System/Library/Frameworks/CoreServices.framework/Headers/CoreServices.h:21,
#                  from ./src/audio/macosx/SDL_coreaudio.c:25:
# /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/MachineExceptions.h:286: error: parse error before '*' token
# /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/MachineExceptions.h:320: error: parse error before '*' token
# In file included from /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/CarbonCore.h:161,
#                  from /System/Library/Frameworks/CoreServices.framework/Headers/CoreServices.h:21,
#                  from ./src/audio/macosx/SDL_coreaudio.c:25:
# /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/fp.h:1338: error: 'SIGDIGLEN' undeclared here (not in a function)
# make: *** [build/SDL_coreaudio.lo] Error 1
