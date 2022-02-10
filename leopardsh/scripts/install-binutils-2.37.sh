#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install binutils on OS X Leopard / PowerPC.

package=binutils
version=2.37

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
        CXXFLAGS="-m64 $(leopard.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(leopard.sh -m32 -mcpu -O)
        CXXFLAGS=$(leopard.sh -m32 -mcpu -O)
    fi
    export CFLAGS CXXFLAGS

    ./configure -C --prefix=/opt/$pkgspec

    make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        make check
    fi

    make install

    leopard.sh --arch-check $pkgspec

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

# checking for isl 0.15 or later... no
# required isl version is 0.15 or later
# *** This configuration is not supported in the following subdirectories:
#      ld gas gprof
#     (Any other directories should still work fine.)

# this is what we currently get:
# macuser@pbookg42(leopard)$ ls /opt/binutils-2.37/bin/
# addr2line c++filt   nm        objdump   readelf   strings
# ar        elfedit   objcopy   ranlib    size      strip
# macuser@pbookg42(leopard)$ ls /opt/binutils-2.37/lib/
# libbfd.a        libctf-nobfd.a  libctf.a        libopcodes.a
# libbfd.la       libctf-nobfd.la libctf.la       libopcodes.la
