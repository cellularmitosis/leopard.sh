#!/bin/bash
# based on templates/template.sh v3

# Install readline on OS X Tiger / PowerPC.

package=readline
version=8.1.2

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

for dep in \
    termcap-1.3.1$ppc64 \
    ncurses-6.3$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    PKG_CONFIG_PATH="/opt/$dep/lib/pkgconfig:$PKG_CONFIG_PATH"
done
export PKG_CONFIG_PATH

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

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 12819fa739a78a6172400f399ab34f81

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(tiger.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(tiger.sh -m32 -mcpu -O)
    fi
    export CFLAGS

    pkgconfignames="ncurses"
    CPPFLAGS=$(pkg-config --cflags-only-I $pkgconfignames)
    LDFLAGS="$LDFLAGS $(pkg-config --libs-only-L $pkgconfignames)"
    LIBS=$(pkg-config --libs-only-l $pkgconfignames)
    export CPPFLAGS LDFLAGS LIBS

    ./configure -C --prefix=/opt/$pkgspec \
        --with-curses

    make $(tiger.sh -j)

    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi

    make install

    leopard.sh --arch-check $pkgspec

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
