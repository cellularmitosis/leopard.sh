#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install hyperspec on OS X Leopard / PowerPC.

package=hyperspec
version=7.0
upstream=http://ftp.lispworks.com/pub/software_tools/reference/HyperSpec-7-0.tar.gz

set -e -x
PATH="/opt/tigersh-deps-0.1/bin:$PATH"

pkgspec=$package-$version

if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$tarball
fi

rm -rf /opt/$pkgspec
mkdir -p /opt/$pkgspec
cd /opt/$pkgspec
tar xzf ~/Downloads/$tarball
