#!/bin/bash

# Install coreutils on OS X Leopard / PowerPC.

package=coreutils
version=9.0

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
fi

if ! test -e /opt/gettext-0.21$ppc64 ; then
    leopard.sh gettext-0.21$ppc64
fi

if ! test -e /opt/gmp-4.3.2$ppc64 ; then
    leopard.sh gmp-4.3.2$ppc64
fi

if ! test -e /opt/libiconv-1.16$ppc64 ; then
    leopard.sh libiconv-1.16$ppc64
fi

if ! test -e /opt/libressl-3.4.2$ppc64 ; then
    leopard.sh libressl-3.4.2$ppc64
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --os.cpu))\007"

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

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 2971e74d6503a901856f1dcc6f00af40

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball
    
    cd $package-$version

    cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache > config.cache

    # Note: fails to build when using the stock gcc, so we use gcc-4.2:
    # gcc -std=gnu99   -mcpu=7450 -O2   -o src/make-prime-list src/make-prime-list.o  
    # gcc -std=gnu99  -I. -I./lib  -Ilib -I./lib -Isrc -I./src -I/opt/libiconv-1.16/include -I/opt/gettext-0.21/include -fPIC   -mcpu=7450 -O2 -MT src/libstdbuf_so-libstdbuf.o -MD -MP -MF src/.deps/libstdbuf_so-libstdbuf.Tpo -c -o src/libstdbuf_so-libstdbuf.o `test -f 'src/libstdbuf.c' || echo './'`src/libstdbuf.c
    # mv -f src/.deps/libstdbuf_so-libstdbuf.Tpo src/.deps/libstdbuf_so-libstdbuf.Po
    # gcc -std=gnu99 -fPIC   -mcpu=7450 -O2 -shared  -o src/libstdbuf.so src/libstdbuf_so-libstdbuf.o -L/opt/gettext-0.21/lib -lintl -liconv -Wl,-framework -Wl,CoreFoundation 
    # Undefined symbols:
    #   "_main", referenced from:
    #       start in crt1.10.5.o
    # ld: symbol(s) not found
    # collect2: ld returned 1 exit status
    # make[2]: *** [src/libstdbuf.so] Error 1
    # make[1]: *** [all-recursive] Error 1
    # make: *** [all] Error 2
    export CC=gcc-4.2

    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(leopard.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(leopard.sh -m32 -mcpu -O)
    fi
    export CFLAGS

    # Note: coreutils ends up linking against /usr/lib/libiconv, despite having
    # used --with-libiconv-prefix=/opt/libiconv...:
    #   $ otool -L /opt/coreutils-9.0/bin/* | grep /usr/lib/libiconv
    #   /usr/lib/libiconv.2.dylib (compatibility version 7.0.0, current version 7.0.0)
    # My guess is that this is some bad interaction between --with-libiconv-prefix and
    # --with-libintl-prefix, based on this configure output:
    #   checking how to link with libiconv... -L/opt/libiconv-1.16/lib -liconv
    #   checking how to link with libintl... -L/opt/gettext-0.21/lib -lintl -liconv -Wl,-framework -Wl,CoreFoundation
    # You end up with some correct lines:
    #   gcc-4.2 -std=gnu99   -mcpu=7450 -O2   -o src/factor src/factor.o src/libver.a lib/libcoreutils.a -L/opt/gettext-0.21/lib -lintl -liconv -Wl,-framework -Wl,CoreFoundation lib/libcoreutils.a  -L/opt/libiconv-1.16/lib -liconv 
    # and some which are incorrect:
    #   gcc-4.2 -std=gnu99   -mcpu=7450 -O2   -o src/chroot src/chroot.o src/libver.a lib/libcoreutils.a -L/opt/gettext-0.21/lib -lintl -liconv -Wl,-framework -Wl,CoreFoundation lib/libcoreutils.a 
    # Coreutils alse ends up linking against /usr/lib/libcrypto:
    #   $ otool -L /opt/coreutils-9.0/bin/* | grep /usr/lib/libcrypto
    #   /usr/lib/libcrypto.0.9.7.dylib (compatibility version 0.9.7, current version 0.9.7)
    # So we need to set the flags manually to overcome this.
    CPPFLAGS="-I/opt/gettext-0.21$ppc64/include -I/opt/gmp-4.3.2$ppc64/include -I/opt/libiconv-1.16$ppc64/include -I/opt/libressl-3.4.2$ppc64/include"
    LDFLAGS="-L/opt/gettext-0.21$ppc64/lib -L/opt/gmp-4.3.2$ppc64/lib -L/opt/libiconv-1.16$ppc64/lib -L/opt/libressl-3.4.2$ppc64/lib"
    export CPPFLAGS LDFLAGS

    ./configure -C --prefix=/opt/$pkgspec \
        --with-openssl=yes \
        --with-libiconv-prefix=/opt/libiconv-1.16$ppc64 \
        --with-libgmp-prefix=/opt/gmp-4.3.2$ppc64 \
        --with-libintl-prefix=/opt/gettext-0.20$ppc64

    make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
        # Note: three test failures on ppc32:
        # FAIL: tests/misc/env-S
        # FAIL: tests/misc/sort-continue
        # FAIL: tests/misc/sort-merge-fdlimit
        make check

        # Note: 221 test failures on ppc64:
        # FAIL:  221
    fi

    make install

    leopard.sh --linker-check $pkgspec
    leopard.sh --arch-check $pkgspec $ppc64

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
