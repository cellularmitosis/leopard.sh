#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install libdvdcss on OS X Tiger / PowerPC.

package=libdvdcss
version=1.4.3
upstream=https://download.videolan.org/pub/libdvdcss/$version/libdvdcss-$version.tar.bz2
description="A portable abstraction library for DVD decryption"

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

if test -n "$ppc64" ; then
    # Unavailable on tiger/ppc64
    # libtool: link: gcc -dynamiclib  -o .libs/libdvdcss.2.dylib  src/.libs/libdvdcss.o src/.libs/device.o src/.libs/css.o src/.libs/ioctl.o src/.libs/error.o    -m64 -mcpu=970 -O2 -Wl,-framework -Wl,CoreFoundation -Wl,-framework -Wl,IOKit   -install_name  /opt/libdvdcss-1.4.3.ppc64/lib/libdvdcss.2.dylib -compatibility_version 5 -current_version 5.0 -Wl,-single_module
    # Undefined symbols:
    #   _CFRelease, referenced from:
    #       _dvdcss_check_device in device.o
    #       _dvdcss_check_device in device.o
    #   _CFDictionarySetValue, referenced from:
    #       _dvdcss_check_device in device.o
    #   ___CFConstantStringClassReference, referenced from:
    #       __cfstring@0 in device.o
    #       __cfstring@0 in device.o
    #   _IOServiceGetMatchingServices, referenced from:
    #       _dvdcss_check_device in device.o
    #   _IOObjectRelease, referenced from:
    #       _dvdcss_check_device in device.o
    #       _dvdcss_check_device in device.o
    #       _dvdcss_check_device in device.o
    #       _dvdcss_check_device in device.o
    #   _kCFBooleanTrue, referenced from:
    #       _kCFBooleanTrue$non_lazy_ptr in device.o
    #   _IOMasterPort, referenced from:
    #       _dvdcss_check_device in device.o
    #   _IORegistryEntryCreateCFProperty, referenced from:
    #       _dvdcss_check_device in device.o
    #   _IOServiceMatching, referenced from:
    #       _dvdcss_check_device in device.o
    #   _CFStringGetCString, referenced from:
    #       _dvdcss_check_device in device.o
    #   _kCFAllocatorDefault, referenced from:
    #       _kCFAllocatorDefault$non_lazy_ptr in device.o
    #   _IOIteratorNext, referenced from:
    #       _dvdcss_check_device in device.o
    #       _dvdcss_check_device in device.o
    # ld64-62.1 failed: symbol(s) not found
    # /usr/libexec/gcc/powerpc-apple-darwin8/4.0.1/libtool: internal link edit command failed
    # make[1]: *** [libdvdcss.la] Error 1
    exit 1
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --disable-maintainer-mode \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(tiger.sh -j) V=1

# Note: no 'make check' available.

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
