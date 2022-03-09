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
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --os.cpu))\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/ncurses
    tarball=ncurses-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = a2736befde5fee7d2b7eb45eb281cdbe

    cd /tmp
    rm -rf ncurses-$version

    tar xzf ~/Downloads/$tarball

    cd ncurses-$version

    cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache > config.cache

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

    ./configure -C --prefix=/opt/$pkgspec \
        --with-manpage-format=normal \
        --with-shared \
        --without-debug \
        $enable_widec \
        CFLAGS="$CFLAGS" \
        CXXFLAGS="$CXXFLAGS"

        # --enable-pc-files \
        # --with-pkg-config-libdir=/opt/$pkgspec/lib/pkgconfig \

    make $(leopard.sh -j) V=1

    # Note: no 'make check' available.

    make install

    leopard.sh --linker-check $pkgspec
    leopard.sh --arch-check $pkgspec $ppc64

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi