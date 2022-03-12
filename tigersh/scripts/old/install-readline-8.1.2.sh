#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install readline on OS X Tiger / PowerPC.

package=readline
version=8.1.2
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    ncurses-6.3$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done
# LIBS="-lbar -lqux"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --os.cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    # Note: readline ends up linking a ppc dylib, rather than ppc64,
    # so we pass -m64 in LDFLAGS:
    LDFLAGS="-m64 $LDFLAGS"
fi

# Note: the dylibs still end up being "ppc" rather than e.g. ppc7400,
# so we also pass -mcpu in LDFLAGS:
LDFLAGS="$(tiger.sh -mcpu) $LDFLAGS"

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-curses \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(tiger.sh -j)

if test -n "$TIGERSH_RUN_TESTS" ; then
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
