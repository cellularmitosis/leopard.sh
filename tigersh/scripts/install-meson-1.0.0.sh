#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install meson on OS X Tiger / PowerPC.

package=meson
version=1.0.0
upstream=https://github.com/mesonbuild/$package/releases/download/$version/$package-$version.tar.gz
description="Open source build system"

set -e -o pipefail

pkgspec=$package-$version
pyspec=python-3.11.2

if ! test -e /opt/$pyspec ; then
    tiger.sh $pyspec
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

pip3 install $package==$version
tiger.sh --link $pyspec
