#!/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install ncurses / ncursesw on OS X Leopard / PowerPC.

# Note: this file builds both the ncurses and ncursesw packages.
if test -n "$(echo $0 | grep 'ncursesw')" ; then
    package=ncursesw
else
    package=ncurses
fi

version=6.3

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --os.cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

leopard.sh --unpack-dist $pkgspec
cd ncurses-$version

CFLAGS=$(leopard.sh -mcpu -O)
CXXFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
fi

# Note: ncurses needs the directory for .pc files to already exist:
mkdir -p /opt/$pkgspec/lib/pkgconfig

if test "$package" = "ncursesw" ; then
    enable_widec="--enable-widec"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-manpage-format=normal \
    --with-shared \
    --without-debug \
    $enable_widec \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS"

    # --enable-pc-files \
    # --with-pkg-config-libdir=/opt/$pkgspec/lib/pkgconfig \

/usr/bin/time make $(leopard.sh -j) V=1

# Note: no 'make check' available.

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
