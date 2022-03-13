#!/bin/bash
# based on templates/build-from-source.sh v6

# Install mpfr on OS X Leopard / PowerPC.

package=mpfr
version=3.1.6
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    gmp-4.3.2$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --os.cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version


CFLAGS=" $(leopard.sh -mcpu -O) -Wall -Wmissing-prototypes -Wpointer-arith"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

# Note: disabling thread-safe because thread-local storage isn't supported until gcc 4.9.
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-thread-safe \
    --with-gmp=/opt/gmp-4.3.2$ppc64 \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(leopard.sh -j)

if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    # Note: 1 failing test:
    #   PASS: toutimpl
    #   ../test-driver: line 107: 60863 Segmentation fault      "$@" > $log_file 2>&1
    make check
fi

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
