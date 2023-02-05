#!/bin/bash
# based on templates/build-from-source.sh v6

# Install CHICKEN Scheme on OS X Leopard / PowerPC.

package=chicken
version=5.3.0
upstream=https://code.call-cc.org/releases/$version/$package-$version.tar.gz

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

if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
fi

if ! test -e /opt/make-4.3 ; then
    leopard.sh make-4.3
fi
export PATH="/opt/make-4.3/bin:$PATH"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CC=gcc-4.2
COPTS="-fno-strict-aliasing -fwrapv -fno-common -DHAVE_CHICKEN_CONFIG_H"
if test -n "$ppc64" ; then
    COPTS="$COPTS -m64"
    LOPTS="-m64"
fi
COPTIM="$(leopard.sh -mcpu -O) -fomit-frame-pointer"

/usr/bin/time make \
    XCODE_DEVELOPER="" \
    XCODE_TOOL_PATH=/usr/bin \
    C_COMPILER="/usr/bin/$CC" \
    C_COMPILER_OPTIONS="$COPTS" \
    C_COMPILER_OPTIMIZATION_OPTIONS="$COPTIM" \
    LINKER_OPTIONS="$LOPTS" \
    PREFIX=/opt/$pkgspec

if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    # Note: one failing test:
    # (FAIL) remainder: flo/flo: expected 0.0 but got -0.0
    make \
        XCODE_DEVELOPER="" \
        XCODE_TOOL_PATH=/usr/bin \
        C_COMPILER="/usr/bin/$CC" \
        C_COMPILER_OPTIONS="$COPTS" \
        C_COMPILER_OPTIMIZATION_OPTIONS="$COPTIM" \
        LINKER_OPTIONS="$LOPTS" \
        PREFIX=/opt/$pkgspec \
        check
fi

make \
    XCODE_DEVELOPER="" \
    XCODE_TOOL_PATH=/usr/bin \
    C_COMPILER="/usr/bin/$CC" \
    C_COMPILER_OPTIONS="$COPTS" \
    C_COMPILER_OPTIMIZATION_OPTIONS="$COPTIM" \
    LINKER_OPTIONS="$LOPTS" \
    PREFIX=/opt/$pkgspec \
    install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
