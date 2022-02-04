#!/bin/bash

# Install bison on OS X Leopard / PowerPC.

package=bison
version=3.8.2

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version
    
    perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(leopard.sh -m64 -mcpu -O)\"/g" configure
    perl -pi -e "s/CXXFLAGS=\"-g -O2\"/CXXFLAGS=\"$(leopard.sh -m64 -mcpu -O)\"/g" configure

    ./configure -C --prefix=/opt/$pkgspec
    make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        # FIXME `make check` fails with:
        # examples/c++/calc++/parser.cc: In constructor 'yy::parser::parser(driver&)':
        # examples/c++/calc++/parser.cc:149: error: the default argument for parameter 0 of 'yy::parser::stack<T, S>::stack(typename S::size_type) [with T = yy::parser::stack_symbol_type, S = std::vector<yy::parser::stack_symbol_type, std::allocator<yy::parser::stack_symbol_type> >]' has not yet been parsed
        # make[3]: *** [examples/c++/calc++/calc__-parser.o] Error 1
        # make[2]: *** [check-am] Error 2
        # make[1]: *** [check-recursive] Error 1
        # make: *** [check] Error 2
        make check
    fi

    make install

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi
