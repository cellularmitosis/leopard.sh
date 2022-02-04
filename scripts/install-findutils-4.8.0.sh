#!/bin/bash

# Install findutils on OS X Leopard / PowerPC.

package=findutils
version=4.8.0

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! which -s xz ; then
    leopard.sh xz-5.2.5
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.xz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    cat ~/Downloads/$tarball | unxz | tar x
    cd $package-$version

    perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(leopard.sh -m64 -mcpu -O)\"/g" configure

    ./configure -C --prefix=/opt/$pkgspec
    make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        # FIXME 'make check' because it requires a more recent python.
        make check
    fi

    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/
