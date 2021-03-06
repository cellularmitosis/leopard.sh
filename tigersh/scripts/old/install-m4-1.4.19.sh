#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install m4 on OS X Tiger / PowerPC.

package=m4
version=1.4.19
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

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

test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = f4a2b0284d80353b995f8ef2385ed73c

cd /tmp
rm -rf $package-$version

tar xzf ~/Downloads/$tarball

cd /tmp/$package-$version

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

for f in configure ; do
    if test -n "$ppc64" ; then
        perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"-m64 $(tiger.sh -mcpu -O)\"/g" $f
    else
        perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(tiger.sh -m32 -mcpu -O)\"/g" $f
    fi
done

if ! test -n "$ppc64" ; then
    # 32-bit tiger ppc fails with:
    # sigsegv.c: In function 'sigsegv_handler':
    # sigsegv.c:938: error: 'struct mcontext' has no member named '__ss'
    # Thanks to https://trac.macports.org/ticket/63381
    perl -pi -e "s/__ss.__r1/ss.r1/g" lib/sigsegv.c
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
    # Note: `make check` currently fails with:
    # test-pthread.c:35: error: 'PTHREAD_RWLOCK_INITIALIZER' undeclared here (not in a function)
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
