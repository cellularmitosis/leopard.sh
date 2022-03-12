#!/bin/bash

# Install python on Leopard / PowerPC.

package=python
version=2.7.18

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

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

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --os.cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

leopard.sh --unpack-dist $pkgspec
    cd Python-$version


    pkgconfignames="readline libressl gdbm"
    CPPFLAGS=$(pkg-config --cflags-only-I $pkgconfignames)
    LDFLAGS="$LDFLAGS $(pkg-config --libs-only-L $pkgconfignames)"
    LIBS=$(pkg-config --libs-only-l $pkgconfignames)
    export CPPFLAGS LDFLAGS LIBS
    /usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
        --with-threads \
        --enable-ipv6

    /usr/bin/time make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        make check
    fi

    make install

    leopard.sh --linker-check $pkgspec
    leopard.sh --arch-check $pkgspec $ppc64

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
        gzip -9 config.cache
        mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
    fi
fi

ln -sf /opt/$pkgspec/bin/python /usr/local/bin/python2

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
