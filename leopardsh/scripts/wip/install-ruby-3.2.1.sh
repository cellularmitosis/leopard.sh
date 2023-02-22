#!/bin/bash
# based on templates/build-from-source.sh v6

# Install ruby on OS X Leopard / PowerPC.

package=ruby
version=3.2.1
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz
description=""

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# 👇 EDIT HERE:
if ! test -e /opt/bar-2.0$ppc64 ; then
    leopard.sh bar-2.0$ppc64
    PATH="/opt/bar-2.0$ppc64/bin:$PATH"
fi

# 👇 EDIT HERE:
for dep in \
    bar-2.1$ppc64 \
    qux-3.4$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done
LIBS="-lbar -lqux"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

if test -z "$ppc64" -a "$(leopard.sh --cpu)" = "g5" ; then
    # fails during a 32-bit build on a G5 machine,
    # so we instead install the g4e binpkg in that case.
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

# 👇 EDIT HERE:
if ! which -s gcc-10.3 ; then
    leopard.sh gcc-10.3.0
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CC=gcc-10.3
CXX=g++-10.3

CFLAGS=$(leopard.sh -mcpu -O)
CXXFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# 👇 EDIT HERE:
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --with-bar=/opt/bar-1.0 \
    --with-bar-prefix=/opt/bar-1.0 \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    LIBS="$LIBS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    CC="$CC" \
    CXX="$CXX"

./configure --prefix=/opt/$pkgspec \
    --enable-shared \
    --with-gmp-dir=/opt/gmp-6.2.1$ppc64 \
    --with-mantype=man \
    --with-rdoc=ri,html \
    CC=gcc-10.3 \
    CXX=g++-10.3 \
    cflags=-O0 \
    cxxflags=-O0

# Configuration summary for ruby version 3.2.1

#    * Installation prefix: /opt/ruby-3.2.1
#    * exec prefix:         ${prefix}
#    * arch:                powerpc-darwin9.0
#    * site arch:           ${arch}
#    * RUBY_BASE_NAME:      ruby
#    * enable shared:       yes
#    * ruby lib prefix:     ${libdir}/${RUBY_BASE_NAME}
#    * site libraries path: ${rubylibprefix}/${sitearch}
#    * vendor path:         ${rubylibprefix}/vendor_ruby
#    * target OS:           darwin9.0
#    * compiler:            gcc-10.3
#    * with thread:         pthread
#    * with coroutine:      ppc
#    * enable shared libs:  yes
#    * dynamic library ext: bundle
#    * CFLAGS:              -O0 ${optflags} ${debugflags} ${warnflags}
#    * LDFLAGS:             -L. -fstack-protector-strong -L/opt/gmp-6.2.1/lib
#    * DLDFLAGS:            -L/opt/gmp-6.2.1/lib \
#                           -Wl,-multiply_defined,suppress \
#                           -Wl,-undefined,dynamic_lookup
#    * optflags:            -O3 -fno-fast-math
#    * debugflags:          -ggdb3
#    * warnflags:           -Wall -Wextra -Wdeprecated-declarations \
#                           -Wdiv-by-zero -Wduplicated-cond \
#                           -Wimplicit-function-declaration -Wimplicit-int \
#                           -Wmisleading-indentation -Wpointer-arith \
#                           -Wwrite-strings -Wold-style-definition \
#                           -Wimplicit-fallthrough=0 -Wmissing-noreturn \
#                           -Wno-cast-function-type \
#                           -Wno-constant-logical-operand -Wno-long-long \
#                           -Wno-missing-field-initializers \
#                           -Wno-overlength-strings \
#                           -Wno-packed-bitfield-compat \
#                           -Wno-parentheses-equality -Wno-self-assign \
#                           -Wno-tautological-compare -Wno-unused-parameter \
#                           -Wno-unused-value -Wsuggest-attribute=format \
#                           -Wsuggest-attribute=noreturn -Wunused-variable \
#                           -Wundef
#    * strip command:       strip -S -x
#    * install doc:         rdoc html
#    * MJIT support:        yes
#    * YJIT support:        no
#    * man page type:       man

# ---



# io.c: At top level:
# cc1: note: unrecognized command-line option '-Wno-self-assign' may have been intended to silence earlier diagnostics
# cc1: note: unrecognized command-line option '-Wno-parentheses-equality' may have been intended to silence earlier diagnostics
# cc1: note: unrecognized command-line option '-Wno-constant-logical-operand' may have been intended to silence earlier diagnostics
# make: *** [io.o] Error 1



# io.c:12683:45: error: 'COPYFILE_STATE_COPIED' undeclared (first use in this function); did you mean 'COPYFILE_STATE_DST_FD'?
# 12683 |     copyfile_state_get(stp->copyfile_state, COPYFILE_STATE_COPIED, &ss); /* get copied bytes */
#       |                                             ^~~~~~~~~~~~~~~~~~~~~
#       |                                             COPYFILE_STATE_DST_FD
# io.c:12683:45: note: each undeclared identifier is reported only once for each function it appears in


/usr/bin/time make $(leopard.sh -j) V=1

# 👇 EDIT HERE:
if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
if test -n "$LEOPARDSH_RUN_LONG_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
# Note: no 'make check' available.

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
