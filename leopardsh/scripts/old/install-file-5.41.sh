#!/bin/bash

# Install file on OS X Leopard / PowerPC.

package=file
version=5.41

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
fi

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
    cd /tmp/$package-$version


    /usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
        CC=gcc-4.2 \
        CFLAGS="-std=c99 $(leopard.sh -m32 -mcpu -O)"
  
    /usr/bin/time make $(leopard.sh -j) V=1

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
