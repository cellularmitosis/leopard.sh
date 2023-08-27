#!/bin/bash
# based on templates/build-from-source.sh v6

# Install meson on OS X Leopard / PowerPC.

package=meson
version=1.2.1
upstream=https://github.com/mesonbuild/$package/releases/download/$version/$package-$version.tar.gz
description="Open source build system"

set -e -o pipefail

pkgspec=$package-$version$ppc64
pyspec=python-3.11.2

if ! test -e /opt/$pyspec ; then
    leopard.sh $pyspec
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

pip3 install $package==$version
leopard.sh --link $pyspec
