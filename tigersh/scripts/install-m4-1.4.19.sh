#!/bin/bash
# based on templates/template.sh v3

# Install m4 on OS X Tiger / PowerPC.

package=m4
version=1.4.19

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
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = f4a2b0284d80353b995f8ef2385ed73c

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

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

    ./configure -C --prefix=/opt/$pkgspec

    make $(tiger.sh -j) V=1

    if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
        # Note: `make check` currently fails with:
        # test-pthread.c:35: error: 'PTHREAD_RWLOCK_INITIALIZER' undeclared here (not in a function)
        make check
    fi

    make install

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
