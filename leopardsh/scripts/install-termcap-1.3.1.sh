#!/bin/bash
# based on templates/template.sh v3

# Install termcap on OS X Leopard / PowerPC.

package=termcap
version=1.3.1

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

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

    # Note: termcap's configure is too old to understand the -C flag,
    # and gets confused by passing it CFLAGS.
    ./configure --cache-file=config.cache --prefix=/opt/$pkgspec

    make $(leopard.sh -j) V=1 CFLAGS="$CFLAGS"

    # Note: no 'make check' available.

    make install

    # Note: termcap does not provide a .pc file, but readline requires one,
    # so we supply one:
    mkdir -p /opt/$pkgspec/lib/pkgconfig
    cat > /opt/$pkgspec/lib/pkgconfig/$package.pc << "EOF"
prefix=/opt/termcap-1.3.1
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include

Name: Termcap
Description: Terminal capability database
URL: https://en.wikipedia.org/wiki/Termcap
Version: 1.3.1
Libs: -L${libdir} -ltermcap
Cflags: -I${includedir}
EOF

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
