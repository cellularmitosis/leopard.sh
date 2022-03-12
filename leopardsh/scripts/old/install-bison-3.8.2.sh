#!/bin/bash

# Install bison on OS X Leopard / PowerPC.

package=bison
version=3.8.2

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# "GNU M4 1.4.6 or later is required; 1.4.16 or newer is recommended."
# The stock m4 on Leopard is 1.4.6, might as well use the latest as recommended.
if ! test -e /opt/m4-1.4.19$ppc64 ; then
    leopard.sh m4-1.4.19$ppc64
fi

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
    

    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(leopard.sh -mcpu -O)"
        CXXFLAGS="-m64 $(leopard.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(leopard.sh -m32 -mcpu -O)
        CXXFLAGS=$(leopard.sh -m32 -mcpu -O)
    fi
    export CFLAGS CXXFLAGS

    /usr/bin/time ./configure -C --prefix=/opt/$pkgspec
    
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
fi




# Optional Packages:
#   --with-PACKAGE[=ARG]    use PACKAGE [ARG=yes]
#   --without-PACKAGE       do not use PACKAGE (same as --with-PACKAGE=no)
#   --with-gnu-ld           assume the C compiler uses GNU ld [default=no]
#   --with-libtextstyle-prefix[=DIR]  search for libtextstyle in DIR/include and DIR/lib
#   --without-libtextstyle-prefix     don't search for libtextstyle in includedir and libdir
#   --with-libiconv-prefix[=DIR]  search for libiconv in DIR/include and DIR/lib
#   --without-libiconv-prefix     don't search for libiconv in includedir and libdir
#   --with-libreadline-prefix[=DIR]  search for libreadline in DIR/include and DIR/lib
#   --without-libreadline-prefix     don't search for libreadline in includedir and libdir
#   --with-libintl-prefix[=DIR]  search for libintl in DIR/include and DIR/lib
#   --without-libintl-prefix     don't search for libintl in includedir and libdir

