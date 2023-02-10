#!/bin/bash
# based on templates/build-from-source.sh v6

# Install chibi-scheme on OS X Leopard / PowerPC.

package=chibi-scheme
version=20230208
upstream=https://github.com/ashinn/$package/archive/refs/heads/master.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# SRFI 144 fails because it is actually C99, not C89:
#   cc  -dynamiclib  -Iinclude  -DSEXP_USE_INTTYPES -Wall -g -g3 -O3   -o lib/srfi/144/math.dylib lib/srfi/144/math.c -L.   -lchibi-scheme
#   lib/srfi/144/math.c: In function 'sexp_compute_least_double':
#   lib/srfi/144/math.c:8: error: 'for' loop initial declaration used outside C99 mode
#   make: *** [lib/srfi/144/math.dylib] Error 1
#
# The easy solution is to just use C99 for everything:
CC="gcc -std=c99"

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"

# Note: ppc64 build fails with:
#   gcc -std=c99  -dynamiclib -install_name /opt/chibi-scheme-20230208.ppc64/lib/libchibi-scheme.0.10.0.dylib -o libchibi-scheme.0.10.0.dylib gc.o sexp.o bignum.o gc_heap.o opcodes.o vm.o eval.o simplify.o -m64    -ldl -lm
#   Undefined symbols:
#     "___multi3", referenced from:
#         _sexp_bignum_fxmul in bignum.o
#         _sexp_bignum_fxrem in bignum.o
#         _sexp_mul in bignum.o
#         _sexp_apply in vm.o
#     "___udivti3", referenced from:
#         _sexp_bignum_fxdiv in bignum.o
#         _sexp_bignum_fxrem in bignum.o
#         _sexp_bignum_quot_rem in bignum.o
#         _sexp_bignum_quot_rem in bignum.o
#   ld: symbol(s) not found
#   collect2: ld returned 1 exit status
#   make: *** [libchibi-scheme.0.10.0.dylib] Error 1
    exit 1
fi

# We'll pass in our own optimization flags.
perl -pi -e "s/-g -g3 -O3//g" Makefile.detect

/usr/bin/time make $(leopard.sh -j) \
    PREFIX=/opt/$pkgspec \
    CC="$CC" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS"

# Note: no 'make check' available.

make PREFIX=/opt/chibi-scheme-20230208 install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
