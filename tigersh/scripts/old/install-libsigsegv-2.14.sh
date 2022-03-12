#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install libsigsegv on OS X Tiger / PowerPC.

package=libsigsegv
version=2.14
upstream=https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

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

test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 63a2b35f11b2fbccc3d82f9e6c6afd58

cd /tmp
rm -rf $package-$version

tar xzf ~/Downloads/$tarball

cd /tmp/$package-$version


CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    # LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --enable-shared \
    CFLAGS="$CFLAGS" \
    # LDFLAGS="$LDFLAGS"

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
