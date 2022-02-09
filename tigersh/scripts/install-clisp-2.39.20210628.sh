#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install clisp on OS X Tiger / PowerPC.

package=clisp
version=2.39.20210628

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.2
fi

if ! test -e /opt/libsigsegv-2.14$ppc64 ; then
    tiger.sh libsigsegv-2.14$ppc64
fi

if ! test -e /opt/libiconv-bootstrap-1.16$ppc64 ; then
    tiger.sh libiconv-bootstrap-1.16$ppc64
fi

if ! test -e /opt/readline-8.1.2$ppc64 ; then
    tiger.sh readline-8.1.2$ppc64
fi

if ! test -e /opt/hyperspec-7.0 ; then
    tiger.sh hyperspec-7.0
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    commit=de01f0f47bb44d3a0f9e842464cf2520b238f356
    srcmirror=https://gitlab.com/gnu-clisp/clisp/-/archive/$commit
    tarball=$package-$commit.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$commit

    tar xzf ~/Downloads/$tarball

    cd $package-$commit

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    cpu=$(tiger.sh --cpu)
    if test "$cpu" = "g5" ; then
        if test -n "$ppc64" ; then
            CC="gcc-4.2 -m64 $(tiger.sh -mcpu -O)"
        else
            CC="gcc-4.2 $(tiger.sh -m32 -mcpu -O)"
        fi
    else
        CC="gcc-4.2 $(tiger.sh -m32 -mcpu -O)"
    fi
    export CC

    ./configure -C --prefix=/opt/$pkgspec \
        --with-libsigsegv-prefix=/opt/libsigsegv-2.14$ppc64 \
        --with-libiconv-prefix=/opt/libiconv-1.16$ppc64 \
        --with-libreadline-prefix=/opt/libreadline-8.1.2$ppc64 \
        --hyperspec=file:///opt/hyperspec-7.0/HyperSpec

    exit 1


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
