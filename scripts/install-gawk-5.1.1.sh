#!/bin/bash

# Install gawk on OS X Leopard / PowerPC.

package=gawk
version=5.1.1

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/mpfr-2.4.2 ; then
    leopard.sh mpfr-2.4.2
fi

if ! test -e /opt/readline-8.1.2 ; then
    leopard.sh readline-8.1.2
fi

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
    ./configure -C --prefix=/opt/$pkgspec \
        --with-mpfr=/opt/mpfr-2.4.2 \
        --with-readline=/opt/readline-8.1.2
    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        # FIXME one failing test.
        make check
    fi

    make install
fi


# Note: using readline-8.1.2 to get "_rl_get_screen_size" and "_rl_completion_matches"
if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi
