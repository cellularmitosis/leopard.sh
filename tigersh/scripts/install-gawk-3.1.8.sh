#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install GNU Awk on OS X Tiger / PowerPC.

package=gawk
version=3.1.8
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz
description="GNU awk pattern-matching language"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    libiconv-1.16$ppc64 \
    gettext-0.20$ppc64 \
    libsigsegv-2.14$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
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

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# Apparently someone decided to hard-code the arch as x86_64 on darwin.
# sed -i '' -e 's|CFLAGS="${CFLAGS} -arch x86_64"|CFLAGS="${CFLAGS}"|' configure

# Something is broken with the extension's handling of config.cache.
#   configure: loading cache ../config.cache
#   configure: error: `LDFLAGS' was not set in the previous run
#   configure: error: in `/tmp/gawk-5.2.1/extension':
#   configure: error: changes in the environment can compromise the build
#   configure: error: run `make distclean' and/or `rm ../config.cache'
#   	    and start over
#   configure: error: ./configure failed for extension
# rm -f config.cache

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --with-libiconv-prefix=/opt/libiconv-1.16$ppc64 \
    --with-libintl-prefix=/opt/gettext-0.21$ppc64 \
    --with-libsigsegv-prefix=/opt/libsigsegv-2.14$ppc64 \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(tiger.sh -j) V=1

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
