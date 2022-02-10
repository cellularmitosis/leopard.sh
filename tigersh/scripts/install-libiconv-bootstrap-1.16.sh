#!/bin/bash
# based on templates/template.sh v3

# Install libiconv on OS X Tiger / PowerPC.

# Note: there is a circular dependency between libiconv and gettext.  This
# package is a second copy of libiconv used to break the circular dependency.

# Quoting from https://www.gnu.org/software/libiconv/
# After installing GNU libiconv for the first time, it is recommended to
# recompile and reinstall GNU gettext, so that it can take advantage of libiconv.
# On systems other than GNU/Linux, the iconv program will be internationalized
# only if GNU gettext has been built and installed before GNU libiconv. This
# means that the first time GNU libiconv is installed, we have a circular
# dependency between the GNU libiconv and GNU gettext packages, which can be
# resolved by building and installing either:
# - first libiconv, then gettext, then libiconv again,
# or (on systems supporting shared libraries, excluding AIX)
# - first gettext, then libiconv, then gettext again.

package=libiconv-bootstrap
version=1.16

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/libiconv
    tarball=libiconv-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 7d2a800b952942bb2880efb00cfd524c

    cd /tmp
    rm -rf libiconv-$version

    tar xzf ~/Downloads/$tarball

    cd libiconv-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(tiger.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(tiger.sh -m32 -mcpu -O)
    fi
    export CFLAGS

    ./configure -C --prefix=/opt/$pkgspec
    
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
