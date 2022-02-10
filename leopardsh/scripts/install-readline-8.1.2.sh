#!/bin/bash
# based on templates/template.sh v3

# Install readline on OS X Leopard / PowerPC.

package=readline
version=8.1.2

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/pkg-config-0.29.2$ppc64 ; then
    leopard.sh pkg-config-0.29.2$ppc64
fi

for dep in \
    termcap-1.3.1$ppc64 \
    ncurses-6.3$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    PKG_CONFIG_PATH="/opt/$dep/lib/pkgconfig:$PKG_CONFIG_PATH"
done
export PKG_CONFIG_PATH

echo -n -e "\033]0;leopard.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
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

    cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache > config.cache

    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(leopard.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(leopard.sh -m32 -mcpu -O)
    fi
    export CFLAGS

    pkgconfignames="ncurses"
    CPPFLAGS=$(pkg-config --cflags-only-I $pkgconfignames)
    LDFLAGS="$LDFLAGS $(pkg-config --libs-only-L $pkgconfignames)"
    LIBS=$(pkg-config --libs-only-l $pkgconfignames)
    export CPPFLAGS LDFLAGS LIBS

    ./configure -C --prefix=/opt/$pkgspec \
        --with-curses

    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        make check
    fi

    make install

    leopard.sh --arch-check $pkgspec

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
