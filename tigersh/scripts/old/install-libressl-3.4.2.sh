#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/template.sh v3

FIXME WIP

# Install libressl on OS X Tiger / PowerPC.

package=libressl
version=3.4.2
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

test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 18aa728e7947a30af3bb04243e4482aa

cd /tmp
rm -rf $package-$version

tar xzf ~/Downloads/$tarball

cd /tmp/$package-$version


for f in configure ; do
    if test -n "$ppc64" ; then
        perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"-m64 $(tiger.sh -mcpu -O)\"/g" $f
        perl -pi -e "s/CFLAGS=\"-O2\"/CFLAGS=\"-m64 $(tiger.sh -mcpu -O)\"/g" $f
    else
        perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(tiger.sh -m32 -mcpu -O)\"/g" $f
        perl -pi -e "s/CFLAGS=\"-O2\"/CFLAGS=\"$(tiger.sh -m32 -mcpu -O)\"/g" $f
    fi
done

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$ppc64" ; then
    # Note: two failing tests on ppc64:
    # FAIL: aeadtest.sh
    # FAIL: gcm128test
    if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
        make check
    fi
else
    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi
fi

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
