#!/bin/bash

# Install file on OS X Leopard / PowerPC.

package=file
version=5.41

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if ! which -s gcc-4.2; then
    leopard.sh gcc-4.2
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/$binpkg | gunzip | tar x
else
    srcmirror=https://astron.com/pub/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version
    CC=gcc-4.2 CFLAGS=-std=c99 ./configure --prefix=/opt/$package-$version
    make

    if test -n "$LEOPARDSH_MAKE_CHECK"; then
        make check
    fi

    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/

# Note: Using gcc-4.2 and -std=c99 to avoid the following failure:
#   readelf.c:1046: error: 'for' loop initial declaration used outside C99 mode
#   c99: invalid argument `all' to -W

# Another failure:
#  CC       readelf.lo
#readelf.c: In function ‘do_auxv_note’:
#readelf.c:1046: error: ‘for’ loop initial declaration used outside C99 mode
#make[3]: *** [readelf.lo] Error 1
#make[2]: *** [all] Error 2
#make[1]: *** [all-recursive] Error 1
#make: *** [all] Error 2
