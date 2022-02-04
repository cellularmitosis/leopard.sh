#!/bin/bash

# Install bc on Tiger / PowerPC.

package=bc
version=5.2.1

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if ! which -s xz; then
    leopard.sh xz-5.2.5
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://github.com/gavinhoward/$package/releases/download/$version
    tarball=$package-$version.tar.xz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    cat ~/Downloads/$tarball | unxz | tar x
    cd $package-$version
    ./configure -C --prefix=/opt/$package-$version
    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS"; then
        make check
    fi

    # FIXME something is messed up during install
    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/
