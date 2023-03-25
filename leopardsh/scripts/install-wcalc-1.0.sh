#!/bin/bash
# based on templates/build-from-source.sh v6

# Install wcalc on OS X Leopard / PowerPC.

package=wcalc
version=1.0
upstream=https://downloads.sourceforge.net/$package/$package-$version.tar.gz
description="A tool for the analysis and synthesis of transmission line structures and related components"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

dep=gtk+-1.2.10$ppc64
if ! test -e /opt/$dep ; then
    leopard.sh $dep
    PATH="/opt/$dep/bin:$PATH"
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

# WARNING:  your awk (awk) does not include the gensub()
#           function.  This prevents the rebuilding of the
#           .html files from the .shtml files.  If you need
#           this functionality, you will need to install gawk.
#           By setting the variable AWK in your configure
#           environment, you can force configure to find a
#           particular awk program.
if ! which -s gawk ; then
    leopard.sh gawk-3.1.8
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS="$(leopard.sh -mcpu -O) $CFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --disable-maintainer-mode \
    --disable-debug \
    --enable-htdocs \
    CFLAGS="$CFLAGS"

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
