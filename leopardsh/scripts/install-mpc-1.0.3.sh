#!/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install mpc on OS X Leopard / PowerPC.

package=mpc
version=1.0.3

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    gmp-4.3.2$ppc64 \
    mpfr-3.1.6$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --os.cpu))\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
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

    cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache > config.cache

    # Non-fat file: lib/libmpc.a is architecture: ppc
    CC="gcc $(leopard.sh -mcpu)"

    CFLAGS="$(leopard.sh -mcpu -O) -pedantic -no-cpp-precomp"
    if test -n "$ppc64" ; then
        CFLAGS="-m64 $CFLAGS"
    fi

    cpu=$(leopard.sh --cpu)
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

    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        make check
    fi

    make install

    leopard.sh --linker-check $pkgspec
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
