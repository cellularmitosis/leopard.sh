#!/bin/bash
# based on templates/build-from-source.sh v6

# Install scheme48 on OS X Leopard / PowerPC.

package=scheme48
version=1.9.2
upstream=https://www.s48.org/$version/$package-$version.tgz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if test -z "$ppc64" -a "$(leopard.sh --cpu)" = "g5" ; then
    echo -e "${COLOR_RED}Error:${COLOR_NONE} 32-bit scheme48 is broken on G5's, but the ppc64 version works." >&2
    echo "Please install $pkgspec.ppc64 instead." >&2
    exit 1
fi

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CC=gcc-4.2

CFLAGS=$(leopard.sh -mcpu -O)
FORCE32=""
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
elif test "$(leopard.sh --cpu)" = "g5" ; then
    # Building with the default flags on a G5 fails with:
    #   ./build/build-usual-image . \
    #   "`(cd . && pwd)`/scheme" "`pwd`/c" 'scheme48.image' './scheme48vm' \
    #   	'./build/initial.image-64'
    #   Unable to correct byte order
    #   make: *** [scheme48.image] Error 255
    #
    # So we force a 32-bit build:
    FORCE32="--enable-force-32bit"

    # Hmm, still failing:
    #   ./build/build-usual-image . \
    #   		"`(cd . && pwd)`/scheme" "`pwd`/c" 'scheme48.image' './scheme48vm' \
    #   		'./build/initial.image-32'
    #   Correcting byte order of resumed image.
    #   VM exception `wrong-type-argument' with no handler in place
    #   opcode is: stored-object-length
    #   stack template id's: 6643 <- 6650 <- 6625 <- 3309 <- 
    #   make: *** [scheme48.image] Error 123
    #
    # Shrug.  We'll just tell the user to use the ppc64 version instead.
    exit 1
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    $FORCE32 \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \
    CC="$CC"

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_LONG_TESTS" ; then
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
