#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install mpdecimal on OS X Tiger / PowerPC.

package=mpdecimal
version=2.5.1
upstream=https://www.bytereef.org/software/mpdecimal/releases/$package-$version.tar.gz
description="Arbitrary precision decimal floating point arithmetic library"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# 👇 EDIT HERE:
# if ! test -e /opt/bar-2.0$ppc64 ; then
#     tiger.sh bar-2.0$ppc64
#     PATH="/opt/bar-2.0$ppc64/bin:$PATH"
# fi

# 👇 EDIT HERE:
# for dep in \
#     bar-2.1$ppc64 \
#     qux-3.4$ppc64
# do
#     if ! test -e /opt/$dep ; then
#         tiger.sh $dep
#     fi
#     CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
#     LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
#     PATH="/opt/$dep/bin:$PATH"
# done
# LIBS="-lbar -lqux"

# libmpdec++ needs C++11
if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
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

# 👇 EDIT HERE:
# if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
#     tiger.sh gcc-4.2
# fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# 👇 EDIT HERE:
CC=gcc-4.9
CXX=g++-4.9

# 👇 EDIT HERE:
CFLAGS=$(tiger.sh -mcpu -O)
CXXFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
    if test "$(tiger.sh --cpu)" = "g5" ; then
        # 64-bit builds on G5 fail with:
        #   mpdecimal.h:187:4: error: #error "unsupported platform: need mpd_size_t == mpd_uint_t"
        # So we force MACHINE=ansi64.
        MCHN="MACHINE=ansi64"
    fi
else
    if test "$(tiger.sh --cpu)" = "g5" ; then
        # 32-bit builds on G5 fail with:
        #   mpdecimal.h:187:4: error: #error "unsupported platform: need mpd_size_t == mpd_uint_t"
        # So we force MACHINE=ansi32.
        MCHN="MACHINE=ansi32"
    fi
fi

# This is the code which is causing the problems:
#   if MPD_SIZE_MAX != MPD_UINT_MAX
#     error "unsupported platform: need mpd_size_t == mpd_uint_t"
#   endif

# 👇 EDIT HERE:
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --enable-shared \
    --enable-cxx \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    CC="$CC" \
    CXX="$CXX" \
    $MCHN

    # MACHINE=$MACHINE \

    # LIBS="$LIBS" \

/usr/bin/time make $(tiger.sh -j) V=1

# 👇 EDIT HERE:
if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
if test -n "$TIGERSH_RUN_LONG_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
# Note: no 'make check' available.

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
