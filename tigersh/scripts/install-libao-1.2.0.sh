#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install libao on OS X Tiger / PowerPC.

package=libao
version=1.2.0
upstream=https://downloads.xiph.org/releases/ao/$package-$version.tar.gz
description="The Audio Output library"

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

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Note: tiger ppc64 build fails with:
#   libtool: compile:  gcc -DPACKAGE_NAME=\"libao\" -DPACKAGE_TARNAME=\"libao\" -DPACKAGE_VERSION=\"1.2.0\" "-DPACKAGE_STRING=\"libao 1.2.0\"" -DPACKAGE_BUGREPORT=\"monty@xiph.org\" -DPACKAGE_URL=\"\" -DPACKAGE=\"libao\" -DVERSION=\"1.2.0\" -DSTDC_HEADERS=1 -DHAVE_SYS_TYPES_H=1 -DHAVE_SYS_STAT_H=1 -DHAVE_STDLIB_H=1 -DHAVE_STRING_H=1 -DHAVE_MEMORY_H=1 -DHAVE_STRINGS_H=1 -DHAVE_INTTYPES_H=1 -DHAVE_STDINT_H=1 -DHAVE_UNISTD_H=1 -DHAVE_DLFCN_H=1 -DLT_OBJDIR=\".libs/\" -DHAVE_DLFCN_H=1 -DHAVE_DLOPEN=1 -DHAVE_LIBPTHREAD=1 "-DDLOPEN_FLAG=(RTLD_LAZY)" -DSHARED_LIB_EXT=\".so\" -DSIZEOF_SHORT=2 -DSIZEOF_INT=4 -DSIZEOF_LONG=8 -I. -I../../../include/ao -I../../../include -D__NO_MATH_INLINES -fsigned-char -m64 -mcpu=970 -O2 -DAO_BUILDING_LIBAO -c ao_macosx.c  -fno-common -DPIC -o .libs/ao_macosx.o
#   In file included from /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/DriverServices.h:32,
#                    from /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/CarbonCore.h:125,
#                    from /System/Library/Frameworks/CoreServices.framework/Headers/CoreServices.h:21,
#                    from ao_macosx.c:37:
#   /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/MachineExceptions.h:286: error: parse error before '*' token
#   /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/MachineExceptions.h:320: error: parse error before '*' token
#   In file included from /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/CarbonCore.h:161,
#                    from /System/Library/Frameworks/CoreServices.framework/Headers/CoreServices.h:21,
#                    from ao_macosx.c:37:
#   /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/fp.h:1338: error: 'SIGDIGLEN' undeclared here (not in a function)
#   make[3]: *** [ao_macosx.lo] Error 1

CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --disable-maintainer-mode \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS"

/usr/bin/time make $(tiger.sh -j) V=1

# 👇 EDIT HERE:
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
