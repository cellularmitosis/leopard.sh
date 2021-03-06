#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install pcre on OS X Tiger / PowerPC.

FIXME wip

package=pcre
version=8.45
upstream=https://ftp.exim.org/pub/pcre/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else

if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$tarball
fi

test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 01b80f8177ab91da63e7e5c5d5dfcb83

cd /tmp
rm -rf $package-$version

tar xzf ~/Downloads/$tarball

cd /tmp/$package-$version


# 👇 EDIT HERE:
export CC=gcc-4.2 CXX=g++-4.2

# 👇 EDIT HERE:
if test -n "$ppc64" ; then
    CFLAGS="-m64 $(tiger.sh -mcpu -O)"
    CXXFLAGS="-m64 $(tiger.sh -mcpu -O)"
    export LDFLAGS=-m64
else
    CFLAGS=$(tiger.sh -m32 -mcpu -O)
    CXXFLAGS=$(tiger.sh -m32 -mcpu -O)
fi
export CFLAGS CXXFLAGS

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
LDFLAGS="$LDFLAGS $(pkg-config --libs-only-L $pkgconfignames)"
LIBS=$(pkg-config --libs-only-l $pkgconfignames)
export CPPFLAGS LDFLAGS LIBS

# 👇 EDIT HERE:
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-bar=/opt/bar-1.0 \
    --with-bar-prefix=/opt/bar-1.0 \

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

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
