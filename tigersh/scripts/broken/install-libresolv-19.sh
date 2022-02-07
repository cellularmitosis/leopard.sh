#!/bin/bash

exit 1
FIXME this is a rabbit hole which I abandoned.

# Install libresolv on OS X Tiger / PowerPC.

package=libresolv
version=19

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

binpkg=$package-$version.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://opensource.apple.com/tarballs/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version

    perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(tiger.sh -m64 -mcpu -O)\"/g" configure

    ./configure -C --prefix=/opt/$package-$version
    make $(tiger.sh -j) V=1

    if test -n "$TIGERSH_MAKE_CHECK"; then
        make check
    fi

    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/

# $ otool -L /usr/lib/libresolv.dylib 
# /usr/lib/libresolv.dylib:
# 	/usr/lib/libresolv.9.dylib (compatibility version 1.0.0, current version 369.5.0)
# 	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 88.1.7)

# dnsinfo.h appears to come from configd:
# https://opensource.apple.com/tarballs/configd/

# in particular, my configd appears to be 136.2, so download
# https://opensource.apple.com/tarballs/configd/configd-136.2.tar.gz

# $ strings /usr/sbin/configd | grep BUILT  
# @(#)PROGRAM:configd  PROJECT:configd-136.2  DEVELOPER:root  BUILT:Dec  2 2006 04:01:37
