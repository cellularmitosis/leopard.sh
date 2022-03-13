#!/bin/bash

# Install gawk on OS X Leopard / PowerPC.

package=gawk
version=5.1.1
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/mpfr-3.1.6$ppc64 ; then
    leopard.sh mpfr-3.1.6$ppc64
fi

if ! test -e /opt/readline-8.1.2$ppc64 ; then
    leopard.sh readline-8.1.2$ppc64
fi

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else

if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$tarball
fi

cd /tmp
rm -rf $package-$version
tar xzf ~/Downloads/$tarball
cd /tmp/$package-$version


/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-mpfr=/opt/mpfr-3.1.6$ppc64 \
    --with-readline=/opt/readline-8.1.2$ppc64

/usr/bin/time make $(leopard.sh -j)

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    # FIXME one failing test.
    make check
fi

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi


# Note: using readline-8.1.2 to get "_rl_get_screen_size" and "_rl_completion_matches"
