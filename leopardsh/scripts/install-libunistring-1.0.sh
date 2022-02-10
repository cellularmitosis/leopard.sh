#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install libunistring on OS X Leopard / PowerPC.

package=libunistring
version=1.0

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: we use libiconv-bootstrap to break a dependency cycle with libiconv.
if ! test -e /opt/libiconv-bootstrap-1.16$ppc64 ; then
    leopard.sh libiconv-bootstrap-1.16$ppc64
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache > config.cache

    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(leopard.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(leopard.sh -m32 -mcpu -O)
    fi
    export CFLAGS

    ./configure -C --prefix=/opt/$pkgspec \
        --with-libiconv-prefix=/opt/libiconv-bootstrap-1.16$ppc64

    make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        # Note: tests faile to compile on leopard ppc64:
        # gcc -std=gnu99 -DHAVE_CONFIG_H -DEXEEXT=\"\" -I. -I. -I../lib -I..  -DIN_LIBUNISTRING_GNULIB_TESTS=1 -I. -I. -I.. -I./.. -I../lib -I./../lib   -Wno-error -m64 -mcpu=970 -O2 -MT test-stdint.o -MD -MP -MF $depbase.Tpo -c -o test-stdint.o test-stdint.c &&\
        # mv -f $depbase.Tpo $depbase.Po
        # test-stdint.c:265: error: negative width in bit-field '_gl_verify_error_if_negative'
        # test-stdint.c:266: error: negative width in bit-field '_gl_verify_error_if_negative'
        # test-stdint.c:415: error: negative width in bit-field '_gl_verify_error_if_negative'
        # make[4]: *** [test-stdint.o] Error 1
        # make[3]: *** [check-am] Error 2
        # make[2]: *** [check-recursive] Error 1
        # make[1]: *** [check] Error 2
        # make: *** [check-recursive] Error 1

        # Note: one failing test on leopard ppc:
        # ../build-aux/test-driver: line 112: 25828 Abort trap              "$@" >> "$log_file" 2>&1
        # FAIL: test-float

        make check
    fi

    make install

    leopard.sh --arch-check $pkgspec $ppc64

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi
