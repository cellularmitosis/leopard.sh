#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install libresolv on OS X Tiger / PowerPC.

package=libresolv
version=19
upstream=https://opensource.apple.com/tarballs/$package/$package-$version.tar.gz

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

test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 1411402275ee7ecfd4bebc5ccfd42962

cd /tmp
rm -rf $package-$version

tar xzf ~/Downloads/$tarball

cd /tmp/$package-$version

curl -#fO https://opensource.apple.com/source/configd/configd-136.2/dnsinfo/dnsinfo.h
curl -#fO https://opensource.apple.com/source/Libinfo/Libinfo-222.3.6/lookup.subproj/netdb_async.h

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

# /usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
#     --with-bar=/opt/bar-1.0 \
#     --with-bar-prefix=/opt/bar-1.0 \
#     CPPFLAGS="$CPPFLAGS" \
#     LDFLAGS="$LDFLAGS" \
#     LIBS="$LIBS" \
#     CFLAGS="$CFLAGS" \
#     CXXFLAGS="$CXXFLAGS" \
#     CC="$CC" \
#     CXX="$CXX"

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

# Note: no 'make check' available.
