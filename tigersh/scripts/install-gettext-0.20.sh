#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install gettext on OS X Tiger / PowerPC.

# Note: gettext provides libintl.

package=gettext
version=0.20

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: there is a dependency cycle between gettext and libiconv.
# See the note in install-libiconv-bootstrap-1.16.sh.
if ! test -e /opt/libiconv-bootstrap-1.16$ppc64 ; then
    tiger.sh libiconv-bootstrap-1.16$ppc64
fi

if ! test -e /opt/libunistring-1.0$ppc64 ; then
    tiger.sh libunistring-1.0$ppc64
fi

if ! test -e /opt/xz-5.2.5$ppc64 ; then
    tiger.sh xz-5.2.5$ppc64
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(hostname -s))\007"

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

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = e71133e1bad4f2ce83121078fd33edde

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(tiger.sh -mcpu -O)"
        CXXFLAGS="-m64 $(tiger.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(tiger.sh -m32 -mcpu -O)
        CXXFLAGS=$(tiger.sh -m32 -mcpu -O)
    fi
    export CFLAGS CXXFLAGS

    ./configure -C --prefix=/opt/$pkgspec \
        --with-libiconv-prefix=/opt/libiconv-bootstrap-1.16$ppc64 \
        --with-libcurses-prefix=/opt/ncurses-6.3$ppc64 \
        --with-libunistring-prefix=/opt/libunistring-1.0$ppc64

    make $(tiger.sh -j) V=1

    if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
        # Four failing tests:
        # FAIL: msgcat-17
        # FAIL: msgfilter-sr-latin-1
        # FAIL: msgmerge-11
        # FAIL: xgettext-python-1
        make check
    fi

    make install

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
