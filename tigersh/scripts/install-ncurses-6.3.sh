#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install ncurses / ncursesw on OS X Tiger / PowerPC.

# Note: this file builds both the ncurses and ncursesw packages.
if test -n "$(echo $0 | grep 'ncursesw')" ; then
    package=ncursesw
else
    package=ncurses
fi

version=6.3
upstream=https://ftp.gnu.org/gnu/ncurses/ncurses-$version.tar.gz

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

tiger.sh --unpack-dist ncurses-$version
cd /tmp/ncurses-$version

CFLAGS=$(tiger.sh -mcpu -O)
CXXFLAGS=$(tiger.sh -mcpu -O)
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
