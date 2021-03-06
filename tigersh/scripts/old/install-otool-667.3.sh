#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install otool on OS X Tiger / PowerPC.

# Tiger's 'otool -L' fails on ppc64 files.
# This package builds Leopard's otool for Tiger.

package=otool
version=667.3
upstream=https://github.com/apple-oss-distributions/cctools/archive/cctools-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

pkgspec=$package-$version$ppc64

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else

if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$tarball
fi

test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = e90e5b27f96eddacd966a3f983a80cbf

cd /tmp
rm -rf cctools-cctools-$version

tar xzf ~/Downloads/$tarball

cd cctools-cctools-$version

# For whatever reason, '#include <ar.h>' is not seeing /usr/include/ar.h.
ln -s /usr/include/ar.h include/

cd libstuff
make
cd ..

cd otool
make
cd ..

mkdir -p /opt/$pkgspec/bin
cp otool/otool.NEW /opt/$pkgspec/bin/otool

mkdir -p /opt/$pkgspec/share/man/man1
cp man/otool.1 /opt/$pkgspec/share/man/man1/

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec
