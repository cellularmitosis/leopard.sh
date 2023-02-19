#!/bin/bash
# based on templates/build-from-source.sh v6

# Install ninja on OS X Leopard / PowerPC.

package=ninja
version=1.11.1
upstream=https://github.com/ninja-build/$package/archive/refs/tags/v$version.tar.gz
description="A small build system similar to make"

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

if ! test -e /opt/python-3.11.2 ; then
    leopard.sh python-3.11.2
    PATH="/opt/python-3.11.2/bin:$PATH"
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

sed -i '' -e 's|#!/usr/bin/env python|#!/usr/bin/env python3|' configure.py

./configure.py --verbose --bootstrap

mkdir -p /opt/$pkgspec/bin
cp ninja /opt/$pkgspec/bin/
rsync -av doc misc /opt/$pkgspec/

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
