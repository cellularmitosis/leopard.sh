#!/bin/bash
# based on templates/template.sh v3

# Install lzo on OS X Tiger / PowerPC.

package=lzo
version=2.10

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=http://www.oberhumer.com/opensource/$package/download
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 39d3f3f9c55c87b1e5d6888e1420f4b5

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    for f in configure ; do
        if test -n "$ppc64" ; then
            perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"-m64 $(tiger.sh -mcpu -O)\"/g" $f
        else
            perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(tiger.sh -m32 -mcpu -O)\"/g" $f
        fi
    done

    ./configure -C --prefix=/opt/$pkgspec
    make $(tiger.sh -j) V=1

    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
        make test
    fi

    make install

    tiger.sh --arch-check $pkgspec $ppc64

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
