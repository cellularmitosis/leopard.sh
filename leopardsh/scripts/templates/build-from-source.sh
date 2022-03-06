#!/bin/bash
# based on templates/build-from-source.sh v5

# 👇 EDIT HERE:
# Install foo on OS X Leopard / PowerPC.

# 👇 EDIT HERE:
package=foo
version=1.0
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# 👇 EDIT HERE:
if ! test -e /opt/bar-2.0$ppc64 ; then
    leopard.sh bar-2.0$ppc64
fi

# 👇 EDIT HERE:
for dep in \
    bar-2.1$ppc64 \
    qux-3.4$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done
LIBS="-lbar -lqux"

# 👇 EDIT HERE:
if ! test -e /opt/pkg-config-0.29.2$ppc64 ; then
    leopard.sh pkg-config-0.29.2$ppc64
fi

# 👇 EDIT HERE:
for dep in \
    bar-2.1$ppc64 \
    qux-3.4$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    PKG_CONFIG_PATH="/opt/$dep/lib/pkgconfig:$PKG_CONFIG_PATH"
done
export PKG_CONFIG_PATH

# 👇 EDIT HERE:
for dep in \
    baz-4.5$ppc64
do
    export PKG_CONFIG_PATH="/opt/$dep/lib/pkgconfig:$PKG_CONFIG_PATH"
done

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

# 👇 EDIT HERE:
if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
fi

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# 👇 EDIT HERE:
cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache > config.cache

# 👇 EDIT HERE:
CC=gcc-4.2
CXX=g++-4.2

# 👇 EDIT HERE:
CFLAGS=$(leopard.sh -mcpu -O)
CXXFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# 👇 EDIT HERE:
for f in configure libfoo/configure ; do
    if test -n "$ppc64" ; then
        perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"-m64 $(leopard.sh -mcpu -O)\"/g" $f
        perl -pi -e "s/CXXFLAGS=\"-g -O2\"/CXXFLAGS=\"-m64 $(leopard.sh -mcpu -O)\"/g" $f
        export LDFLAGS=-m64
    else
        perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(leopard.sh -mcpu -O)\"/g" $f
        perl -pi -e "s/CXXFLAGS=\"-g -O2\"/CXXFLAGS=\"$(leopard.sh -mcpu -O)\"/g" $f
    fi
done

# 👇 EDIT HERE:
pkgconfignames="bar qux"
CPPFLAGS=$(pkg-config --cflags-only-I $pkgconfignames)
LDFLAGS="$LDFLAGS $(pkg-config --libs-only-L $pkgconfignames)"
LIBS=$(pkg-config --libs-only-l $pkgconfignames)

    # 👇 EDIT HERE:
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-bar=/opt/bar-1.0 \
    --with-bar-prefix=/opt/bar-1.0 \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    LIBS="$LIBS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    CC="$CC" \
    CXX="$CXX"

/usr/bin/time make $(leopard.sh -j) V=1

# 👇 EDIT HERE:
if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
if test -n "$LEOPARDSH_RUN_LONG_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
# Note: no 'make check' available.

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
