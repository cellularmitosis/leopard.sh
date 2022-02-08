#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install clisp on OS X Tiger / PowerPC.

package=clisp
version=2.39.20210628

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.2
fi

if ! test -e /opt/libsigsegv-2.14$ppc64 ; then
    leopard.sh libsigsegv-2.14$ppc64
fi

if ! test -e /opt/hyperspec-7.0 ; then
    leopard.sh hyperspec-7.0
fi

# Note: ppc64 pkg-config unavailable on Tiger.
if ! test -e /opt/pkg-config-0.29.2 ; then
    tiger.sh pkg-config-0.29.2
fi

# 👇 EDIT HERE:
# for dep in \
#     bar-2.1$ppc64 \
#     qux-3.4$ppc64
# do
#     if ! test -e /opt/$dep ; then
#         tiger.sh $dep
#     fi
#     export PKG_CONFIG_PATH="/opt/$dep/lib/pkgconfig:$PKG_CONFIG_PATH"
# done

# 👇 EDIT HERE:
# for dep in \
#     baz-4.5$ppc64
# do
#     export PKG_CONFIG_PATH="/opt/$dep/lib/pkgconfig:$PKG_CONFIG_PATH"
# done

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

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    cpu=$(tiger.sh --cpu)
    if test "$cpu" = "g5" ; then
        if test -n "$ppc64" ; then
            CC="gcc-4.2 -m64 $(tiger.sh -mcpu -O)"
        else
            CC="gcc-4.2 $(tiger.sh -m32 -mcpu -O)"
        fi
    else
        CC="gcc-4.2 $(tiger.sh -m32 -mcpu -O)"
    fi
    export CC

    # 👇 EDIT HERE:
    # pkgconfignames="bar qux"
    # CPPFLAGS=$(pkg-config --cflags-only-I $pkgconfignames)
    # LDFLAGS="$LDFLAGS $(pkg-config --libs-only-L $pkgconfignames)"
    # LIBS=$(pkg-config --libs-only-l $pkgconfignames)
    # export CPPFLAGS LDFLAGS LIBS

    ./configure -C --prefix=/opt/$pkgspec \
        --with-libsigsegv-prefix=/opt/libsigsegv-2.14$ppc64 \
        --hyperspec=file:///opt/hyperspec-7.0/HyperSpec

    make $(tiger.sh -j) V=1

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
