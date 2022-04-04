#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install SDL_mixer 1.2 on OS X Tiger / PowerPC.

package=sdl_mixer
version=1.2.13.20220314
upstream=https://github.com/SDL-mirror/SDL_mixer/archive/refs/heads/SDL-1.2.zip

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
    # when building for ppc64, fails with:
    #   libtool: compile:  gcc -mcpu=970 -O2 -m64 -m64 -mcpu=970 -O2 -I./include -D_GNU_SOURCE=1 -DTARGET_API_MAC_CARBON -DTARGET_API_MAC_OSX -fvisibility=hidden -I/usr/X11R6/include -DXTHREADS -D_THREAD_SAFE -faltivec -force_cpusubtype_ALL -fpascal-strings -Wall -c ./src/audio/macosx/SDL_coreaudio.c  -fno-common -DPIC -o build/.libs/SDL_coreaudio.o
    #   In file included from /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/DriverServices.h:32,
    #                   from /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/CarbonCore.h:125,
    #                   from /System/Library/Frameworks/CoreServices.framework/Headers/CoreServices.h:21,
    #                   from ./src/audio/macosx/SDL_coreaudio.c:25:
    #   /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/MachineExceptions.h:286: error: parse error before '*' token
    #   /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/MachineExceptions.h:320: error: parse error before '*' token
    #   In file included from /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/CarbonCore.h:161,
    #                   from /System/Library/Frameworks/CoreServices.framework/Headers/CoreServices.h:21,
    #                   from ./src/audio/macosx/SDL_coreaudio.c:25:
    #   /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/fp.h:1338: error: 'SIGDIGLEN' undeclared here (not in a function)
    #   make: *** [build/SDL_coreaudio.lo] Error 1
    # 
    # According to Chris Espinosa (apparently Apple employee number 8?):
    #   "If it's Tiger, you can't compile against Carbon.h for architecture ppc64."
    # From https://lists.apple.com/archives/Xcode-users/2007/Jun/msg00469.html
    echo "Error: not available for ppc64." >&2
fi

pkgspec=$package-$version$ppc64

for dep in \
    sdl-1.2.15.20220129$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

patch -p0 << "EOF"
--- native_midi/native_midi_macosx.c.orig	2022-04-03 21:04:20.000000000 -0500
+++ native_midi/native_midi_macosx.c	2022-04-03 21:04:35.000000000 -0500
@@ -201,7 +201,7 @@
      * So, we use MusicSequenceLoadSMFData() for powerpc versions
      * but the *WithFlags() on intel which require 10.4 anyway. */
     # if defined(__ppc__) || defined(__POWERPC__)
-    if (MusicSequenceLoadSMFData(song->sequence, data) != noErr)
+    if (MusicSequenceLoadSMFData(retval->sequence, data) != noErr)
         goto fail;
     # else
     if (MusicSequenceLoadSMFDataWithFlags(retval->sequence, data, 0) != noErr)
EOF

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS"

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
