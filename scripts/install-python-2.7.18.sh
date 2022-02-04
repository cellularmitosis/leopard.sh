#!/bin/bash

# Install python on Tiger / PowerPC.

package=python
version=2.7.18

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    readline-8.1.2 \
    libressl-3.4.2 \
    gdbm-1.22 \
    pkg-config-0.29.2
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    PKG_CONFIG_PATH="/opt/$dep/lib/pkgconfig:$PKG_CONFIG_PATH"
done
export PKG_CONFIG_PATH

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://www.python.org/ftp/$package/$version
    tarball=Python-$version.tgz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd Python-$version

    pkgconfignames="readline libressl gdbm"
    CPPFLAGS=$(pkg-config --cflags-only-I $pkgconfignames)
    LDFLAGS=$(pkg-config --libs-only-L $pkgconfignames)
    LIBS=$(pkg-config --libs-only-l $pkgconfignames)
    export CPPFLAGS LDFLAGS LIBS
    ./configure -C --prefix=/opt/$package-$version \
        --with-threads \
        --enable-ipv6

    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        make check
    fi

    make install
fi

ln -sf /opt/$package-$version/bin/python /usr/local/bin/python2

# configure: WARNING: unrecognized options: --with-openssl

# Python build finished, but the necessary bits to build these modules were not found:
# _bsddb             gdbm               linuxaudiodev   
# ossaudiodev        readline           spwd            
# sunaudiodev                                           
# To find the necessary bits, look in setup.py in detect_modules() for the module's name.
# 
# 
# Failed to build these modules:
# _ssl                                


# hmm, still getting this even after all of the pkgconfig stuff:
# Python build finished, but the necessary bits to build these modules were not found:
# _bsddb             gdbm               linuxaudiodev   
# ossaudiodev        readline           spwd            
# sunaudiodev                                           
# To find the necessary bits, look in setup.py in detect_modules() for the module's name.
# 
# 
# Failed to build these modules:
# _ssl                                                  


# I see this in the configure output:
# checking for pkg-config... /usr/local/bin/pkg-config
# checking pkg-config is at least version 0.9.0... yes
