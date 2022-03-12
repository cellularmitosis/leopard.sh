#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install cloog on OS X Tiger / PowerPC.

package=cloog
version=0.18.1
upstream=https://gcc.gnu.org/pub/gcc/infrastructure/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    gmp-4.3.2$ppc64 \
    isl-0.12.2$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
done

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

CFLAGS="-fomit-frame-pointer -fstrict-aliasing -ffast-math $(tiger.sh -mcpu -O)"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-isl-prefix=/opt/isl-0.12.2$ppc64 \
    --with-gmp-prefix=/opt/gmp-4.3.2$ppc64 \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    # FIXME some tests are failing
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
