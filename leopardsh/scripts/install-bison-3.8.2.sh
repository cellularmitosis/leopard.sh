#!/bin/bash
# based on templates/build-from-source.sh v6

# Install bison on OS X Leopard / PowerPC.

package=bison
version=3.8.2
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz
description="A general-purpose (yacc-compatible) parser generator"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

#   checking for GNU M4 that supports accurate traces... configure: error: no acceptable m4 could be found in $PATH.
#   GNU M4 1.4.6 or later is required; 1.4.16 or newer is recommended.
#   GNU M4 1.4.15 uses a buggy replacement strstr on some systems.
#   Glibc 2.9 - 2.12 and GNU M4 1.4.11 - 1.4.15 have another strstr bug.
# Leopard ships with m4-1.4.6, which meets the requirement, but we might as well use the latest.
if ! test -e /opt/m4-1.4.19 ; then
    leopard.sh m4-1.4.19
    PATH="/opt/m4-1.4.19/bin:$PATH"
fi

for dep in \
    readline-8.2$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done
# LIBS="-lreadline"

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if test -z "$ppc64" -a "$(leopard.sh --cpu)" = "g5" ; then
    # bison seems to abort (during 'make check') on G5's, so we divert to the g4e package.
    #   make  examples/c/bistromathic/bistromathic examples/c/calc/calc examples/c/glr/c++-types examples/c/lexcalc/lexcalc examples/c/mfcalc/mfcalc examples/c/pushcalc/calc examples/c/reccalc/reccalc examples/c/rpcalc/rpcalc examples/c++/calc++/calc++   examples/c++/variant    ./tests/bison tests/atconfig tests/atlocal
    #     YACC     examples/c/bistromathic/parse.c
    #   /tmp/bison-3.8.2/./tests/bison: line 33:  5270 Abort trap              $PREBISON "$abs_top_builddir/src/bison" ${1+"$@"}
    #   make[3]: *** [examples/c/bistromathic/parse.c] Error 134
    #   make[2]: *** [check-am] Error 2
    if leopard.sh --install-binpkg $pkgspec leopard.g4e ; then
        exit 0
    fi
else
    if leopard.sh --install-binpkg $pkgspec ; then
        exit 0
    fi
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --enable-threads=posix \
    --with-libreadline-prefix=/opt/readline-8.2$ppc64 \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    # 'make check' fails with:
    # examples/c++/calc++/parser.cc: In constructor 'yy::parser::parser(driver&)':
    # examples/c++/calc++/parser.cc:149: error: the default argument for parameter 0 of 'yy::parser::stack<T, S>::stack(typename S::size_type) [with T = yy::parser::stack_symbol_type, S = std::vector<yy::parser::stack_symbol_type, std::allocator<yy::parser::stack_symbol_type> >]' has not yet been parsed
    # make[3]: *** [examples/c++/calc++/calc__-parser.o] Error 1
    # make[2]: *** [check-am] Error 2
    # make[1]: *** [check-recursive] Error 1
    # make: *** [check] Error 2
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
