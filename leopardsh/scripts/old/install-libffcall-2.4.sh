#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install libffcall on OS X Leopard / PowerPC.

package=libffcall
version=2.4

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = e7ef6e7cab40f6e224a89cc8dec6fc15

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd /tmp/$package-$version

    FIXME WIP
    cp ~/tmp/gettext/get_ppid_of.h libtextstyle/lib/
    cp ~/tmp/gettext/fix1/get_ppid_of.c libtextstyle/lib/


    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(leopard.sh -mcpu -O)"
        CXXFLAGS="-m64 $(leopard.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(leopard.sh -m32 -mcpu -O)
        CXXFLAGS=$(leopard.sh -m32 -mcpu -O)
    fi
    export CFLAGS CXXFLAGS

    /usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
        --with-threads=posix

    /usr/bin/time make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
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



# Note: ppc64 fails to build:
# cd avcall && make all
# case "darwin9.8.0" in \
# 	  aix*) syntax=aix;; \
# 	  *) syntax=linux;; \
# 	esac; \
# 	case ${syntax} in \
# 	  linux) \
# 	    gcc -std=gnu99 -E `if test true = true; then echo '-DASM_UNDERSCORE'; fi` ./avcall-powerpc64-${syntax}.S | grep -v '^ *#line' | grep -v '^#' | sed -e 's,% ,%,g' -e 's,//.*$,,' > avcall-powerpc64.s || exit 1 ;; \
# 	  *) \
# 	    cp ./avcall-powerpc64-${syntax}.s avcall-powerpc64.s || exit 1 ;; \
# 	esac
# /bin/sh ../libtool --mode=compile gcc -std=gnu99 -x none -c avcall-powerpc64.s
# libtool: compile:  gcc -std=gnu99 -x none -c avcall-powerpc64.s  -fno-common -DPIC -o .libs/avcall-powerpc64.o
# avcall-powerpc64.c:2:unknown .machine argument: power4
# avcall-powerpc64.c:3:Expected comma after segment-name
# avcall-powerpc64.c:3:Rest of line ignored. 1st junk character valued 32 ( ).
# avcall-powerpc64.c:9:Invalid mnemonic 'tocbase,0'
# avcall-powerpc64.c:10:Unknown pseudo-op: .previous
# avcall-powerpc64.c:11:Unknown pseudo-op: .type
# avcall-powerpc64.c:11:Rest of line ignored. 1st junk character valued 97 (a).
# avcall-powerpc64.c:11:Invalid mnemonic 'function'
# avcall-powerpc64.c:13:Parameter syntax error (parameter 1)
