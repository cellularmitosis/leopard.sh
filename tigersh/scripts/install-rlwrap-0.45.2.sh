#!/bin/bash
# based on templates/template.sh v3

# Install rlwrap on OS X Tiger / PowerPC.

package=rlwrap
version=0.45.2

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/pkg-config-0.29.2$ppc64 ; then
    tiger.sh pkg-config-0.29.2$ppc64
fi

for dep in \
    readline-8.1.2$ppc64
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
    srcmirror=https://github.com/hanslub42/$package/releases/download/v$version
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
        export LDFLAGS=-m64
    else
        CFLAGS=$(tiger.sh -m32 -mcpu -O)
    fi
    export CFLAGS

    pkgconfignames="readline"
    CPPFLAGS=$(pkg-config --cflags-only-I $pkgconfignames)
    LDFLAGS=$(pkg-config --libs-only-L $pkgconfignames)
    LIBS=$(pkg-config --libs-only-l $pkgconfignames)
    export CPPFLAGS LDFLAGS LIBS

    ./configure -C --prefix=/opt/$pkgspec

    make $(tiger.sh -j) V=1

    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi

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
