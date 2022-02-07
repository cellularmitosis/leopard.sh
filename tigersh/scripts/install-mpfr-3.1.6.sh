#!/bin/bash
# based on templates/template.sh v1

# Install mpfr on OS X Tiger / PowerPC.

package=mpfr
version=3.1.6

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gmp-4.3.2$ppc64 ; then
    tiger.sh gmp-4.3.2$ppc64
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

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version

    # Note: disabling thread-safe because thread-local storage isn't supported until gcc 4.9.
    ./configure -C --prefix=/opt/$pkgspec \
        --disable-thread-safe \
        --with-gmp=/opt/gmp-4.3.2$ppc64 \
        CFLAGS="-Wall -Wmissing-prototypes -Wpointer-arith $(tiger.sh -m32 -mcpu -O)"

    make $(tiger.sh -j)

    if test -n "$TIGERSH_RUN_TESTS" ; then
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


# test output on 32-bit ppc:
#
# PASS: tout_str
# PASS: toutimpl
# ../test-driver: line 107: 13936 Segmentation fault      "$@" >$log_file 2>&1
# FAIL: tpow
# PASS: tpow3
# ...
# ============================================================================
# Testsuite summary for MPFR 3.1.6
# ============================================================================
# TOTAL: 160
# PASS:  158
# SKIP:  1
# XFAIL: 0
# FAIL:  1
# XPASS: 0
# ERROR: 0
