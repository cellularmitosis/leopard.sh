#!/bin/bash
# based on templates/build-from-source.sh v6

# Install harfbuzz on OS X Leopard / PowerPC.

package=harfbuzz
version=7.0.1
upstream=https://github.com/harfbuzz/harfbuzz/releases/download/$version/$package-$version.tar.xz
description="An OpenType text shaping engine"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gcc-4.9.4 ; then
    leopard.sh gcc-libs-4.9.4
fi

# 👇 EDIT HERE:
# dep=bar-1.0$ppc64
# if ! test -e /opt/$dep ; then
#     leopard.sh $dep
#     PATH="/opt/$dep/bin:$PATH"
# fi

# 👇 EDIT HERE:
# for dep in \
#     bar-2.1$ppc64 \
#     qux-3.4$ppc64
# do
#     if ! test -e /opt/$dep ; then
#         leopard.sh $dep
#     fi
#     CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
#     LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
#     PATH="/opt/$dep/bin:$PATH"
#     PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
# done
# LIBS="-lbar -lqux"
# PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"

# 👇 EDIT HERE:
# if ! perl -e "use Text::Unidecode" >/dev/null 2>&1 ; then
#     echo no | cpan
#     cpan Text::Unidecode
# fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

# 👇 EDIT HERE:
# if test -z "$ppc64" -a "$(leopard.sh --cpu)" = "g5" ; then
#     # Fails during a 32-bit build on a G5 machine,
#     # so we instead install the g4e binpkg in that case.
#     if leopard.sh --install-binpkg $pkgspec leopard.g4e ; then
#         exit 0
#     fi
# else
#     if leopard.sh --install-binpkg $pkgspec ; then
#         exit 0
#     fi
# fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

# 👇 EDIT HERE:
# if ! which -s gcc-4.2 ; then
#     leopard.sh gcc-4.2
# fi
# CC=gcc-4.2
# CXX=g++-4.2

if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9.4
fi
CC=gcc-4.9
CXX=g++-4.9

# 👇 EDIT HERE:
# if ! test -e /opt/ld64-97.17-tigerbrew ; then
#     leopard.sh ld64-97.17-tigerbrew
# fi
# export PATH="/opt/ld64-97.17-tigerbrew/bin:$PATH"
# CC='gcc -B/opt/ld64-97.17-tigerbrew/bin'
# CXX='gxx -B/opt/ld64-97.17-tigerbrew/bin'

# 👇 EDIT HERE:
# if ! which -s pkg-config ; then
#     leopard.sh pkg-config-0.29.2
# fi
# export PATH="/opt/pkg-config-0.29.2/bin:$PATH"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# 👇 EDIT HERE:
CFLAGS="$(leopard.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(leopard.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# 👇 EDIT HERE:
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --disable-maintainer-mode \
    --disable-debug \
    CC="$CC" \
    CXX="$CXX" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    # --with-bar=/opt/bar-1.0$ppc64 \
    # --with-bar-prefix=/opt/bar-1.0$ppc64 \
    # LDFLAGS="$LDFLAGS" \
    # CPPFLAGS="$CPPFLAGS" \
    # LIBS="$LIBS" \
    # PKG_CONFIG=/opt/pkg-config-0.29.2/bin/pkg-config \
    # PKG_CONFIG_PATH="/opt/libfoo-1.0$ppc64/lib/pkgconfig:/opt/libbar-1.0$ppc64/lib/pkgconfig" \

/usr/bin/time make $(leopard.sh -j) V=1

# 👇 EDIT HERE:
if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
# if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
#     make check
# fi

# 👇 EDIT HERE:
# if test -n "$LEOPARDSH_RUN_LONG_TESTS" ; then
#     make check
# fi

# 👇 EDIT HERE:
# Note: no 'make check' available.

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi

# lots and lots of errors
# g++-4.9 -std=gnu++11 -DHAVE_CONFIG_H -I. -I..  -pthread           -fno-rtti -mcpu=970 -O2  -fno-exceptions -fno-threadsafe-statics -fvisibility-inlines-hidden -c -o main-main.o `test -f 'main.cc' || echo './'`main.cc
# /bin/sh ../libtool  --tag=CXX   --mode=compile g++-4.9 -std=gnu++11 -DHAVE_CONFIG_H -I. -I..  -pthread            -fno-rtti -mcpu=970 -O2  -fno-exceptions -fno-threadsafe-statics -fvisibility-inlines-hidden -c -o libharfbuzz_la-hb-aat-layout.lo `test -f 'hb-aat-layout.cc' || echo './'`hb-aat-layout.cc
# libtool: compile:  g++-4.9 -std=gnu++11 -DHAVE_CONFIG_H -I. -I.. -pthread -fno-rtti -mcpu=970 -O2 -fno-exceptions -fno-threadsafe-statics -fvisibility-inlines-hidden -c hb-aat-layout.cc  -fno-common -DPIC -o .libs/libharfbuzz_la-hb-aat-layout.o
# In file included from hb.hh:513:0,
#                  from hb-static.cc:27,
#                  from main.cc:350:
# hb-algs.hh: In function 'bool hb_unsigned_mul_overflows(unsigned int, unsigned int, unsigned int*)':
# hb-algs.hh:882:53: error: '__builtin_mul_overflow' was not declared in this scope
#    return __builtin_mul_overflow (count, size, result);
#                                                      ^
# In file included from hb.hh:513:0,
#                  from hb-aat-layout.cc:28:
# hb-algs.hh: In function 'bool hb_unsigned_mul_overflows(unsigned int, unsigned int, unsigned int*)':
# hb-algs.hh:882:53: error: '__builtin_mul_overflow' was not declared in this scope
#    return __builtin_mul_overflow (count, size, result);
#                                                      ^
# In file included from hb.hh:508:0,
#                  from hb-static.cc:27,
#                  from main.cc:350:
# hb-map.hh: In instantiation of 'struct hb_hashmap_t<unsigned int, unsigned int, true>':
# hb-map.hh:477:19:   required from here
# hb-map.hh:336:29: error: cannot call member function 'unsigned int hb_hashmap_t<K, V, minus_one>::size() const [with K = unsigned int; V = unsigned int; bool minus_one = true]' without object
#      + hb_iter (items, size ())
