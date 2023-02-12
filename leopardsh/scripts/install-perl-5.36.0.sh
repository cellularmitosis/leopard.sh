#!/bin/bash
# based on templates/build-from-source.sh v6

# Install perl on OS X Leopard / PowerPC.

# Note: this is a minimal build of perl which is only used to configure OpenSSL.

package=perl
version=5.36.0
upstream=https://www.cpan.org/src/5.0/$package-$version.tar.gz
description="Larry Wall's Practical Extraction and Report Language"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# gcc-4.2 needed for -Wno-error=implicit-function-declaration.
CC=gcc-4.2

CC="$CC" ./configure.gnu --prefix=/opt/$pkgspec

# LD_RUN_PATH="/usr/lib" env MACOSX_DEPLOYMENT_TARGET=10.3 gcc-4.2 -Wl,-rpath,"/usr/lib" -bundle -undefined dynamic_lookup -L/usr/local/lib -fstack-protector  NDBM_File.o  -o ../../lib/auto/NDBM_File/NDBM_File.bundle -ldbm
# ld: -rpath can only be used when targeting Mac OS X 10.5 or later
# collect2: ld returned 1 exit status
# make[1]: *** [../../lib/auto/NDBM_File/NDBM_File.bundle] Error 1

sed -i '' -e 's/MACOSX_DEPLOYMENT_TARGET=10.3/MACOSX_DEPLOYMENT_TARGET=10.5/' config.sh
./Configure -der

/usr/bin/time make $(leopard.sh -j) OPTIMIZE='-O0'

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make test
fi

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
