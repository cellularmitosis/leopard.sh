#!/bin/bash
# based on templates/template.sh v3

# 👇 EDIT HERE:
# Install foo on OS X Tiger / PowerPC.

# 👇 EDIT HERE:
package=foo
version=1.0

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# 👇 EDIT HERE:
if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.2
fi

# 👇 EDIT HERE:
if ! test -e /opt/pkg-config-0.29.2$ppc64 ; then
    tiger.sh pkg-config-0.29.2$ppc64
fi

# 👇 EDIT HERE:
for dep in \
    bar-2.1$ppc64 \
    qux-3.4$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    PKG_CONFIG_PATH="/opt/$dep/lib/pkgconfig:$PKG_CONFIG_PATH"
done
export PKG_CONFIG_PATH

echo -n -e "\033]0;tiger.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    # 👇 EDIT HERE:
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz
    tarball=$package-$version.tar.bz2
    tarball=$package-$version.tar.xz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version

    # 👇 EDIT HERE:
    tar xzf ~/Downloads/$tarball
    tar xjf ~/Downloads/$tarball
    cat ~/Downloads/$tarball | unxz | tar x

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    # 👇 EDIT HERE:
    export CC=gcc-4.2 CXX=g++-4.2

    # 👇 EDIT HERE:
    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(tiger.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(tiger.sh -m32 -mcpu -O)
    fi
    export CFLAGS

    # 👇 EDIT HERE:
    for f in configure libfoo/configure ; do
        if test -n "$ppc64" ; then
            perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"-m64 $(tiger.sh -mcpu -O)\"/g" $f
            perl -pi -e "s/CXXFLAGS=\"-g -O2\"/CXXFLAGS=\"-m64 $(tiger.sh -mcpu -O)\"/g" $f
            export LDFLAGS=-m64
        else
            perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(tiger.sh -m32 -mcpu -O)\"/g" $f
            perl -pi -e "s/CXXFLAGS=\"-g -O2\"/CXXFLAGS=\"$(tiger.sh -m32 -mcpu -O)\"/g" $f
        fi
    done

    # 👇 EDIT HERE:
    pkgconfignames="bar qux"
    CPPFLAGS=$(pkg-config --cflags-only-I $pkgconfignames)
    LDFLAGS=$(pkg-config --libs-only-L $pkgconfignames)
    LIBS=$(pkg-config --libs-only-l $pkgconfignames)
    export CPPFLAGS LDFLAGS LIBS

    # 👇 EDIT HERE:
    ./configure -C --prefix=/opt/$pkgspec \
        --with-bar=/opt/bar-1.0 \
        --with-bar-prefix=/opt/bar-1.0 \

    make $(tiger.sh -j) V=1

    # 👇 EDIT HERE:
    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi

    # 👇 EDIT HERE:
    if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
        make check
    fi

    # 👇 EDIT HERE:
    if test -n "$TIGERSH_RUN_LONG_TESTS" ; then
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
