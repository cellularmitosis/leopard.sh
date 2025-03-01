#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install Hugs98 on OS X Tiger / PowerPC.

package=hugs98
version=sep2006
upstream=https://www.haskell.org/hugs/downloads/2006-09/hugs98-plus-Sep2006.tar.gz
description="A Haskell 98 interpreter"

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

CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(tiger.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

sed -i '' -e "s/OPTFLAGS=\"-O2\"/OPTFLAGS=\"$(tiger.sh -mcpu -O)\"/" configure

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --disable-maintainer-mode \
    --disable-debug \
    --enable-ffi \
    --enable-char-encoding=utf8 \
    --with-pthreads \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \

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
