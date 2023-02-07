#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install the Racket fork of ChezScheme on OS X Leopard / PowerPC.

package=chezscheme
version=9.5.9-racket-20230127
upstream=https://github.com/racket/ChezScheme/archive/refs/heads/master.tar.gz

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

if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.2
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CC=gcc-4.2

CFLAGS=$(tiger.sh -mcpu -O)

# I haven't gotten 64-bit support working yet.  Fails with:
#   : tppc32osx/bin/tppc32osx/scheme
#   running tppc32osx/bin/tppc32osx/scheme to build tppc32osx/s/cmacros.so
#   sizeof(ptr) * 8 [8] != ptr_bits [32]
#   sizeof(long) * 8 [8] != long_bits [32]
#   sizeof(size_t) * 8 [8] != size_t_bits [32]
#   sizeof(ssize_t) * 8 [8] != size_t_bits [32]
#   sizeof(ptrdiff_t) * 8 [8] != ptrdiff_t_bits [32]
#   sizeof(time_t) * 8 [8] != time_t_bits [32]
#   failed
#    in build-one
#    in loop
#    in module->hash
#   make: *** [build] Error 1

# BITS=""
# if test -n "$ppc64" ; then
#     BITS="--64"
#     CFLAGS="$CFLAGS -m64"
# fi

if test -n "$ppc64" ; then
    echo "Sorry, 64-bit support currently unavailable." >&2
    exit 1
fi

./configure \
    --machine=tppc32osx \
    --installprefix=/opt/$pkgspec \
    --threads \
    --installschemename=chezscheme \
    --as-is \
    $BITS \
    CFLAGS="$CFLAGS" \
    CC="$CC"

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
