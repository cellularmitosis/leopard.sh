#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install hyperspec on OS X Leopard / PowerPC.

package=hyperspec
version=7.0

set -e -x
PATH="/opt/portable-curl/bin:$PATH"

pkgspec=$package-$version

srcmirror=http://ftp.lispworks.com/pub/software_tools/reference
tarball=HyperSpec-7-0.tar.gz

if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$tarball
fi

rm -rf /opt/$pkgspec
mkdir -p /opt/$pkgspec
cd /opt/$pkgspec
tar xzf ~/Downloads/$tarball
