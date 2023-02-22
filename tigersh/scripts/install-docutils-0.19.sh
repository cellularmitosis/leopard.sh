#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install docutils on OS X Tiger / PowerPC.

package=docutils
version=0.19
upstream=https://files.pythonhosted.org/packages/6b/5c/330ea8d383eb2ce973df34d1239b3b21e91cd8c865d21ff82902d952f91f/$package-$version.tar.gz
description="Text processing system for reStructuredText"

set -e -o pipefail

pkgspec=$package-$version
pyspec=python-3.11.2

if ! test -e /opt/$pyspec ; then
    tiger.sh $pyspec
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

pip3 install $package==$version
tiger.sh --link $pyspec
