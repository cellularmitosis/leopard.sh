#!/bin/bash
# based on templates/build-from-source.sh v6

# Install lame on OS X Leopard / PowerPC.

package=lame
version=3.100
upstream=https://sourceforge.net/projects/$package/files/$package/$version/$package-$version.tar.gz/download
description="LAME Ain't an MP3 Encoder"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: we need -lMacportsLegacySupport for strnlen.
#   Undefined symbols:
#     "_strnlen", referenced from:
#         _parse_args_ in parse.o
#         _parse_args_ in parse.o
#   ld: symbol(s) not found
dep=macports-legacy-support-20221029$ppc64
if ! test -e /opt/$dep ; then
    leopard.sh $dep
fi
CPPFLAGS="-I/opt/$dep/include/LegacySupport $CPPFLAGS"
LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
PATH="/opt/$dep/bin:$PATH"
LIBS="-lMacportsLegacySupport"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS="$(leopard.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(leopard.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# Fails with:
#   libtool: link: gcc -dynamiclib  -o .libs/libmp3lame.0.dylib  .libs/VbrTag.o .libs/bitstream.o .libs/encoder.o .libs/fft.o .libs/gain_analysis.o .libs/id3tag.o .libs/lame.o .libs/newmdct.o .libs/presets.o .libs/psymodel.o .libs/quantize.o .libs/quantize_pvt.o .libs/reservoir.o .libs/set_get.o .libs/tables.o .libs/takehiro.o .libs/util.o .libs/vbrquantize.o .libs/version.o .libs/mpglib_interface.o   .libs/libmp3lame.lax/libmpgdecoder.a/common.o .libs/libmp3lame.lax/libmpgdecoder.a/dct64_i386.o .libs/libmp3lame.lax/libmpgdecoder.a/decode_i386.o .libs/libmp3lame.lax/libmpgdecoder.a/interface.o .libs/libmp3lame.lax/libmpgdecoder.a/layer1.o .libs/libmp3lame.lax/libmpgdecoder.a/layer2.o .libs/libmp3lame.lax/libmpgdecoder.a/layer3.o .libs/libmp3lame.lax/libmpgdecoder.a/tabinit.o   -lm    -install_name  /opt/lame-3.100/lib/libmp3lame.0.dylib -compatibility_version 1 -current_version 1.0 -Wl,-single_module -Wl,-exported_symbols_list,.libs/libmp3lame-symbols.expsym
#   Undefined symbols:
#     "_lame_init_old", referenced from:
#        -exported_symbols_list command line option
#   ld: symbol(s) not found
#   collect2: ld returned 1 exit status
#   make[3]: *** [libmp3lame.la] Error 1
# Thanks to https://github.com/macports/macports-ports/blob/master/audio/lame/files/patch-avoid_undefined_symbols_error.diff
sed -i '' -e '/lame_init_old/d' include/libmp3lame.sym

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --enable-mp3rtp \
    --disable-static \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    LIBS="$LIBS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS"

/usr/bin/time make $(leopard.sh -j) V=1

# Note: no 'make check' available.

make install

mkdir -p /opt/$pkgspec/lib/pkgconfig
# Based on https://github.com/audacity/audacity/blob/Audacity-3.0.3-RC2/linux/build-environment/pkgconfig/lame.pc
cat > /opt/$pkgspec/lib/pkgconfig/lame.pc << EOF
prefix=/opt/$pkgspec
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: lame
Description: MP3 encoding library
Requires:
Version: $version
Libs: -L\${libdir} -lmp3lame
Cflags: -I\${includedir}
EOF

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
