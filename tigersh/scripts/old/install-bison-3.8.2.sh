#!/opt/tigersh-deps-0.1/bin/bash

# Install bison on OS X Tiger / PowerPC.

package=bison
version=3.8.2
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# On Tiger, building with the stock m4 results in:
# GNU M4 1.4.6 or later is required; 1.4.16 or newer is recommended.
if ! test -e /opt/m4-1.4.19$ppc64 ; then
    tiger.sh m4-1.4.19$ppc64
fi

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


if test -n "$ppc64" ; then
    CFLAGS="-m64 $(tiger.sh -mcpu -O)"
    CXXFLAGS="-m64 $(tiger.sh -mcpu -O)"
    export LDFLAGS=-m64
else
    CFLAGS=$(tiger.sh -m32 -mcpu -O)
    CXXFLAGS=$(tiger.sh -m32 -mcpu -O)
fi
export CFLAGS CXXFLAGS

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
    # The tests fail to build:
    # gcc -std=gnu99 -DEXEEXT=\"\"   -DBISON_LOCALEDIR='""' -DLOCALEDIR='""' -I./examples/c/bistromathic -I./examples/c/bistromathic     -mcpu=7450 -O2 -MT examples/c/bistromathic/bistromathic-parse.o -MD -MP -MF examples/c/bistromathic/.deps/bistromathic-parse.Tpo -c -o examples/c/bistromathic/bistromathic-parse.o `test -f 'examples/c/bistromathic/parse.c' || echo './'`examples/c/bistromathic/parse.c
    # examples/c/bistromathic/parse.c: In function 'completion':
    # examples/c/bistromathic/parse.c:2411: error: 'rl_attempted_completion_over' undeclared (first use in this function)
    # examples/c/bistromathic/parse.c:2411: error: (Each undeclared identifier is reported only once
    # examples/c/bistromathic/parse.c:2411: error: for each function it appears in.)
    # make[3]: *** [examples/c/bistromathic/bistromathic-parse.o] Error 1
    # make[2]: *** [check-am] Error 2
    # make[1]: *** [check-recursive] Error 1
    # make: *** [check] Error 2

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
