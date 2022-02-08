#!/bin/bash
# based on templates/template.sh v3

# Install ncurses on OS X Tiger / PowerPC.

package=ncurses
version=6.3

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: ppc64 pkg-config unavailable on Tiger.
if ! test -e /opt/pkg-config-0.29.2 ; then
    tiger.sh pkg-config-0.29.2
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(tiger.sh -mcpu -O)"
        CXXFLAGS="-m64 $(tiger.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(tiger.sh -m32 -mcpu -O)
        CXXFLAGS=$(tiger.sh -m32 -mcpu -O)
    fi
    export CFLAGS CXXFLAGS

    # Note: ncurses needs the directory for .pc files to already exist:
    mkdir -p /opt/$pkgspec/lib/pkgconfig

    ./configure -C --prefix=/opt/$pkgspec \
        --with-manpage-format=normal \
        --enable-widec \
        --enable-pc-files \
        --with-pkg-config-libdir=/opt/$pkgspec/lib/pkgconfig \
        --with-shared \
        --without-debug

    make $(tiger.sh -j) V=1

    # Note: no 'make check' available.

    make install

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi


# gcc -DHAVE_CONFIG_H -DBUILDING_NCURSES -I../ncurses -I. -I../include -D_DARWIN_C_SOURCE -DNDEBUG -O2 -no-cpp-precomp --param max-inline-insns-single=1200  -DNCURSES_STATIC -c ../ncurses/./base/lib_redrawln.c -o ../objects/lib_redrawln.o
# gcc -DHAVE_CONFIG_H -DBUILDING_NCURSES -I../ncurses -I. -I../include -D_DARWIN_C_SOURCE -DNDEBUG -O2 -no-cpp-precomp --param max-inline-insns-single=1200  -DNCURSES_STATIC -c ../ncurses/./base/lib_refresh.c -o ../objects/lib_refresh.o
# gcc -DHAVE_CONFIG_H -DBUILDING_NCURSES -I../ncurses -I. -I../include -D_DARWIN_C_SOURCE -DNDEBUG -O2 -no-cpp-precomp --param max-inline-insns-single=1200  -DNCURSES_STATIC -c ../ncurses/./base/lib_restart.c -o ../objects/lib_restart.o

# gcc -DHAVE_CONFIG_H -DBUILDING_NCURSES -I../ncurses -I. -I../include -D_APPLE_C_SOURCE -D_XOPEN_SOURCE=600 -DSIGWINCH=28 -DNDEBUG -m32 -mcpu=970 -O2 -no-cpp-precomp --param max-inline-insns-single=1200  -DNCURSES_STATIC -g -DTRACE -c ../ncurses/./base/legacy_coding.c -o ../obj_g/legacy_coding.o