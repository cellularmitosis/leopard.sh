#!/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install mpc on OS X Tiger / PowerPC.

package=mpc
version=1.0.3

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    gmp-4.3.2$ppc64 \
    mpfr-3.1.6$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --os.cpu))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://gcc.gnu.org/pub/gcc/infrastructure
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = d6a1d5f8ddea3abd2cc3e98f58352d26

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    # Non-fat file: lib/libmpc.a is architecture: ppc
    CC="gcc $(tiger.sh -mcpu)"

    CFLAGS="$(tiger.sh -mcpu -O) -pedantic -no-cpp-precomp"
    if test -n "$ppc64" ; then
        CFLAGS="-m64 $CFLAGS"
    fi

    cpu=$(tiger.sh --cpu)
    if test "$cpu" = "g4e" \
    || test "$cpu" = "g4" \
    || test "$cpu" = "g5" -a -z "$ppc64"
    then
        # Note: see the comments in install-gmp-4.3.2.sh re: force_cpusubtype_ALL.
        CFLAGS="$CFLAGS -force_cpusubtype_ALL"
    fi

    ./configure -C --prefix=/opt/$pkgspec \
        --with-gmp=/opt/gmp-4.3.2$ppc64 \
        --with-mpfr=/opt/mpfr-3.1.6$ppc64 \
        CFLAGS="$CFLAGS" \
        LDFLAGS="$LDFLAGS" \
        CC="$CC"
        # CPPFLAGS="$CPPFLAGS" \

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
