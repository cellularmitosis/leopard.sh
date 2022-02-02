#!/bin/bash

# Install gmp on OS X Leopard / PowerPC.

package=gmp
version=4.3.2

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if ! which -s gcc-4.2; then
    leopard.sh gcc-4.2
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version

    perl -pi -e "s/-O3/$(leopard.sh -O)/g" configure
    perl -pi -e "s/-O2/$(leopard.sh -O)/g" configure

    CC=gcc-4.2 CXX=g++-4.2 \
    ./configure -C \
        --prefix=/opt/$package-$version \
        --enable-cxx
    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_MAKE_CHECK"; then
        make check
    fi

    make install

    if test "$(leopard.sh --cpu)" = "g5"; then
        # On G5, build universal libs which contain both ppc and ppc64.
        cd /tmp/$package-$version
        make clean
        CC=gcc-4.2 CXX=g++-4.2 \
        ABI=mode32 \
        ./configure \
            --prefix=/tmp/$package-$version.ppc \
            --enable-cxx
        make $(leopard.sh -j)

        if test -n "$LEOPARDSH_MAKE_CHECK"; then
            make check
        fi

        for f in libgmp.3.5.2.dylib libgmpxx.4.1.2.dylib ; do
            mv /opt/$package-$version/lib/$f /opt/$package-$version/lib/$f.orig
            lipo -create \
                -arch ppc64 /opt/$package-$version/lib/$f.orig \
                -arch ppc /tmp/$package-$version/.libs/$f \
                -output /opt/$package-$version/lib/$f
            rm /opt/$package-$version/lib/$f.orig
        done
    fi
fi

# Note: /usr/bin/gcc (4.0.1) fails with:
#   ld: duplicate symbol ___gmpz_abs in .libs/compat.o and .libs/assert.o
# So we use gcc-4.2 instead.
# Thanks to https://gmplib.org/list-archives/gmp-bugs/2010-January/001837.html
