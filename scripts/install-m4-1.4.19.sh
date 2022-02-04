#!/bin/bash

# Install m4 on OS X Leopard / PowerPC.

package=m4
version=1.4.19

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
    ./configure -C --prefix=/opt/$pkgspec
    make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        # Note: `make check` currently fails with:
        # Skipped checks were:
        #   ./125.changeword ./126.changeword ./127.changeword ./128.changeword ./129.changeword ./130.changeword
        # Failed checks were:
        #   ./198.sysval:err
        # make[3]: *** [check-local] Error 1
        # make[2]: *** [check-am] Error 2
        # make[1]: *** [check-recursive] Error 1
        # make: *** [check] Error 2
        make check
    fi

    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/

