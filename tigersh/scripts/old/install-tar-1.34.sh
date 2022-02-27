#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install tar on OS X Tiger / PowerPC.
# FIXME it appears this version of tar has problems untarring tarballs
# created by the stock os x tar:
#   tar xzf /Users/macuser/Downloads/gzip-1.11.tar.gz
#   tar: gzip-1.11/tests: Cannot utime: Invalid argument
#   tar: gzip-1.11: Cannot utime: Invalid argument
#   tar: Exiting with failure status due to previous errors
# There is only one google hit for this exact error:
#   https://bugs.launchpad.net/ubuntu/+source/linux-meta-hwe/+bug/1820499

package=tar
version=1.34

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gettext-0.20$ppc64 ; then
    tiger.sh gettext-0.20$ppc64
fi

if ! test -e /opt/libiconv-1.16$ppc64 ; then
    tiger.sh libiconv-1.16$ppc64
fi

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

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 9d5949e4c2d9665546ac65dafc0e726a

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(tiger.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(tiger.sh -m32 -mcpu -O)
    fi
    export CFLAGS

    ./configure -C --prefix=/opt/$pkgspec \
        --with-libiconv-prefix=/opt/libiconv-1.16$ppc64 \
        --with-libintl-prefix=/opt/gettext-0.20$ppc64

    make $(tiger.sh -j) V=1

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
