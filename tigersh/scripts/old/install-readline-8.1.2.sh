#!/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install readline on OS X Tiger / PowerPC.

package=readline
version=8.1.2

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    ncurses-6.3$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done
# LIBS="-lbar -lqux"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --os.cpu))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 12819fa739a78a6172400f399ab34f81

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    CFLAGS=$(tiger.sh -mcpu -O)
    if test -n "$ppc64" ; then
        CFLAGS="-m64 $CFLAGS"
        # Note: readline ends up linking a ppc dylib, rather than ppc64,
        # so we pass -m64 in LDFLAGS:
        LDFLAGS="-m64 $LDFLAGS"
    fi

    # Note: the dylibs still end up being "ppc" rather than e.g. ppc7400,
    # so we also pass -mcpu in LDFLAGS:
    LDFLAGS="$(tiger.sh -mcpu) $LDFLAGS"

    ./configure -C --prefix=/opt/$pkgspec \
        --with-curses \
        CPPFLAGS="$CPPFLAGS" \
        LDFLAGS="$LDFLAGS" \
        CFLAGS="$CFLAGS"

    make $(tiger.sh -j)

    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi

    make install

    tiger.sh --linker-check $pkgspec
    tiger.sh --arch-check $pkgspec $ppc64

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi