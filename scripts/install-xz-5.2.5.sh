#!/bin/bash

# Install xz on OS X Leopard / PowerPC.

package=xz
version=5.2.5

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://tukaani.org/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version
    
    perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(leopard.sh -m64 -mcpu -O)\"/g" configure
    
    ./configure -C --prefix=/opt/$package-$version
    make

    if test -n "$LEOPARDSH_MAKE_CHECK"; then
        make check
    fi

    make install

    if test "$(leopard.sh --cpu)" = "g5"; then
        # On G5, build universal libs which contain both ppc and ppc64.
        cd /tmp/$package-$version
        perl -pi -e "s/-m64/-m32/g" configure
        make clean
        ./configure -C --prefix=/opt/$package-$version
        make

        if test -n "$LEOPARDSH_MAKE_CHECK"; then
            make check
        fi

        for f in liblzma.5.dylib ; do
            mv /opt/$package-$version/lib/$f /opt/$package-$version/lib/$f.orig
            lipo -create \
                -arch ppc64 /opt/$package-$version/lib/$f.orig \
                -arch ppc /tmp/$package-$version/src/liblzma/.libs/$f \
                -output /opt/$package-$version/lib/$f
            rm /opt/$package-$version/lib/$f.orig
        done
    fi
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/
