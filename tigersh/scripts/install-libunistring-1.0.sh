#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install libunistring on OS X Tiger / PowerPC.

package=libunistring
version=1.0

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: we use libiconv-bootstrap to break a dependency cycle with libiconv.
if ! test -e /opt/libiconv-bootstrap-1.16$ppc64 ; then
    tiger.sh libiconv-bootstrap-1.16$ppc64
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

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 342070c1e18e74c66a836f79f334c4eb

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
        --with-libiconv-prefix=/opt/libiconv-bootstrap-1.16$ppc64

    make $(tiger.sh -j) V=1

    if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
        # Note: the tests fail to compile:
        # test-pthread.c:35: error: 'PTHREAD_RWLOCK_INITIALIZER' undeclared here (not in a function)
        # make[4]: *** [test-pthread.o] Error 1
        # make[3]: *** [check-am] Error 2
        # make[2]: *** [check-recursive] Error 1
        # make[1]: *** [check] Error 2
        # make: *** [check-recursive] Error 1
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
