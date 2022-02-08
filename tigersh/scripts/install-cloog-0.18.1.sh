#!/bin/bash
# based on templates/template.sh v1


# Install cloog on OS X Tiger / PowerPC.

package=cloog
version=0.18.1

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gmp-4.3.2$ppc64 ; then
    tiger.sh gmp-4.3.2$ppc64
fi

if ! test -e /opt/isl-0.12.2$ppc64 ; then
    tiger.sh isl-0.12.2$ppc64
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://gcc.gnu.org/pub/gcc/infrastructure
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

    for f in configure ; do
        if test -n "$ppc64" ; then
            CFLAGS="-fomit-frame-pointer -fstrict-aliasing -ffast-math -m64 $(tiger.sh -mcpu -O)"
        else
            CFLAGS="-fomit-frame-pointer -fstrict-aliasing -ffast-math $(tiger.sh -m32 -mcpu -O)"
        fi
    done
    export CFLAGS

    ./configure -C --prefix=/opt/$pkgspec \
        --with-isl-prefix=/opt/isl-0.12.2$ppc64 \
        --with-gmp-prefix=/opt/gmp-4.3.2$ppc64

    make $(tiger.sh -j) V=1

    if test -n "$TIGERSH_RUN_TESTS" ; then
        # FIXME some tests are failing
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
