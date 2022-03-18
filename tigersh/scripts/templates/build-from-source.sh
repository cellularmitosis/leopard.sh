#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# 👇 EDIT HERE:
# Install foo on OS X Tiger / PowerPC.

# 👇 EDIT HERE:
package=foo
version=1.0
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# 👇 EDIT HERE:
if ! test -e /opt/bar-2.0$ppc64 ; then
    tiger.sh bar-2.0$ppc64
    PATH="/opt/bar-2.0$ppc64/bin:$PATH"
fi

# 👇 EDIT HERE:
for dep in \
    bar-2.1$ppc64 \
    qux-3.4$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done
LIBS="-lbar -lqux"

# 👇 EDIT HERE:
# Note: ppc64 pkg-config unavailable on Tiger.
if ! test -e /opt/pkg-config-0.29.2 ; then
    tiger.sh pkg-config-0.29.2
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
    PATH="/opt/$dep/bin:$PATH"
done
export PKG_CONFIG_PATH

# 👇 EDIT HERE:
for dep in \
    baz-4.5$ppc64
do
    export PKG_CONFIG_PATH="/opt/$dep/lib/pkgconfig:$PKG_CONFIG_PATH"
done

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

# 👇 EDIT HERE:
if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.2
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# 👇 EDIT HERE:
CC=gcc-4.2
CXX=g++-4.2

# 👇 EDIT HERE:
CFLAGS=$(tiger.sh -mcpu -O)
CXXFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# 👇 EDIT HERE:
for f in configure libfoo/configure ; do
    if test -n "$ppc64" ; then
        perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"-m64 $(tiger.sh -mcpu -O)\"/g" $f
        perl -pi -e "s/CXXFLAGS=\"-g -O2\"/CXXFLAGS=\"-m64 $(tiger.sh -mcpu -O)\"/g" $f
        export LDFLAGS=-m64
    else
        perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(tiger.sh -mcpu -O)\"/g" $f
        perl -pi -e "s/CXXFLAGS=\"-g -O2\"/CXXFLAGS=\"$(tiger.sh -mcpu -O)\"/g" $f
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

/usr/bin/time make $(tiger.sh -j) V=1

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

# 👇 EDIT HERE:
# Note: no 'make check' available.

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
