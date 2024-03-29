#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install gc on OS X Tiger / PowerPC.

package=gc
version=8.2.2
upstream=https://www.hboehm.info/gc/gc_source/$package-$version.tar.gz
description="The Boehm-Demers-Weiser conservative garbage collector"

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

atomic_version=7.6.14
atomic_tarball=libatomic_ops-${atomic_version}.tar.gz
atomic_url=$TIGERSH_MIRROR/dist/$atomic_tarball
echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $atomic_tarball into /tmp/$package-$version." >&2
tiger.sh --unpack-tarball-check-md5 $atomic_url /tmp/$package-$version
mv libatomic_ops-${atomic_version} libatomic_ops

CFLAGS=$(tiger.sh -mcpu -O)
CXXFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"

    # The 64-bit G5 build fails:
    #   libtool: compile:  gcc -DHAVE_CONFIG_H -I./include -I./include -I./libatomic_ops/src -I./libatomic_ops/src -fexceptions -Wall -Wextra -m64 -mcpu=970 -O2 -fno-strict-aliasing -MT os_dep.lo -MD -MP -MF .deps/os_dep.Tpo -c os_dep.c  -fno-common -DPIC -o .libs/os_dep.o
    #   os_dep.c: In function 'catch_exception_raise':
    #   os_dep.c:4884: error: 'ppc_exception_state64_t' has no member named '__dar'
    #   make[1]: *** [os_dep.lo] Error 1
    exit 1
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --enable-cplusplus \
    --enable-static \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS"

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
