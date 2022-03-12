#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install mpfr on OS X Tiger / PowerPC.

package=mpfr
version=3.1.6
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    gmp-4.3.2$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
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


CFLAGS=" $(tiger.sh -mcpu -O) -Wall -Wmissing-prototypes -Wpointer-arith"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

# Note: disabling thread-safe because thread-local storage isn't supported until gcc 4.9.
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-thread-safe \
    --with-gmp=/opt/gmp-4.3.2$ppc64 \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(tiger.sh -j)

if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
    # Note: 1 failing test:
    #   PASS: toutimpl
    #   ../test-driver: line 107: 60863 Segmentation fault      "$@" > $log_file 2>&1
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
