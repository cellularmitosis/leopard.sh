#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install hyperspec on OS X Tiger / PowerPC.

package=hyperspec
version=7.0

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"

pkgspec=$package-$version


if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$tarball
fi

test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 8df440c9f1614e2acfa5e9a360c8969a

rm -rf /opt/$pkgspec
mkdir -p /opt/$pkgspec
cd /opt/$pkgspec
tar xzf ~/Downloads/$tarball
upstream=http://ftp.lispworks.com/pub/software_tools/reference/HyperSpec-7-0.tar.gz
