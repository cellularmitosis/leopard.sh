#!/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install clisp on OS X Leopard / PowerPC.

package=clisp
version=2.39.20210628

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
    leopard.sh gcc-4.2
fi

if ! test -e /opt/hyperspec-7.0 ; then
    leopard.sh hyperspec-7.0
fi

for dep in \
    gettext-0.21$ppc64 \
    libffcall-2.4$ppc64 \
    libiconv-bootstrap-1.16$ppc64 \
    libsigsegv-2.14$ppc64 \
    libunistring-1.0$ppc64 \
    readline-8.1.2$ppc64
    # lightning-2.1.3$ppc64
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
    cd /tmp/$package-$commit

    # Note: stock leopard gcc fails with:
    #   gcc -std=gnu99 -DHAVE_CONFIG_H -I. -I..   -I/opt/libiconv-bootstrap-1.16/include -I/opt/libunistring-1.0/include -I/opt/libsigsegv-2.14/include -I/opt/gettext-0.21/include -I/opt/libffcall-2.4/include -I/opt/readline-8.1.2/include  -g -O2 -W -Wswitch -Wcomment -Wpointer-arith -Wreturn-type -Wmissing-declarations -Wimplicit -Wno-sign-compare -Wno-format-nonliteral -O2 -fwrapv -fno-strict-aliasing -DUNIX_BINARY_DISTRIB -DNO_ASM -DENABLE_UNICODE -DDYNAMIC_MODULES  -fno-common -DPIC  -MT localcharset.o -MD -MP -MF $depbase.Tpo -c -o localcharset.o localcharset.c &&\
    #   mv -f $depbase.Tpo $depbase.Po
    #   localcharset.c: In function 'locale_charset':
    #   localcharset.c:1057: internal compiler error: Bus error
    #   Please submit a full bug report,
    #   with preprocessed source if appropriate.
    #   See <URL:http://developer.apple.com/bugreporter> for instructions.
    #   make[3]: *** [localcharset.o] Error 1
    #   make[2]: *** [all-recursive] Error 1
    #   make[1]: *** [all] Error 2
    #   make: *** [gllib/libgnu.a] Error 2
    # So we use gcc-4.2.
    CC=gcc-4.2

    CFLAGS=$(leopard.sh -mcpu -O)
    if test -n "$ppc64" ; then
        CFLAGS="-m64 $CFLAGS"
        LDFLAGS="-m64 $LDFLAGS"
    fi

    /usr/bin/time ./configure --prefix=/opt/$pkgspec \
        --with-ffcall \
        --with-unicode \
        --with-threads=POSIX_THREADS \
        --hyperspec=file:///opt/hyperspec-7.0/HyperSpec \
        --with-libffcall-prefix=/opt/libffcall-2.4$ppc64 \
        --with-libiconv-prefix=/opt/libiconv-bootstrap-1.16$ppc64 \
        --with-libintl-prefix=/opt/gettext-0.21$ppc64 \
        --with-libreadline-prefix=/opt/readline-8.1.2$ppc64 \
        --with-libsigsegv-prefix=/opt/libsigsegv-2.14$ppc64 \
        --with-libunistring-prefix=/opt/libunistring-1.0$ppc64 \
            --with-module=asdf \
            --with-module=editor \
            --with-module=syscalls \
        CFLAGS="$CFLAGS" \
        LDFLAGS="$LDFLAGS" \
        CC="$CC"
  
            # --with-module=berkeley-db \
            # --with-module=bindings/glibc \
            # --with-module=bindings/win32 \
            # --with-module=clx/mit-clx \
            # --with-module=clx/new-clx \
            # --with-module=dbus \
            # --with-module=dirkey \
            # --with-module=fastcgi \
            # --with-module=gdbm \
            # --with-module=gtk2 \
            # --with-module=i18n \
            # --with-module=libsvm \
            # --with-module=matlab \
            # --with-module=netica \
            # --with-module=oracle \
            # --with-module=pari \
            # --with-module=pcre \
            # --with-module=postgresql \
            # --with-module=queens \
            # --with-module=rawsock \
            # --with-module=readline \
            # --with-module=regexp \
            # --with-module=zlib \

        # --with-jitc=lightning
        # --with-lightning-prefix=/opt/lightning-2.1.3$ppc64 \

# * modules/berkeley-db (try also './modules/berkeley-db/configure --help')
#   --with-libdb-prefix[=DIR]  search for libdb in DIR/include and DIR/lib
# * modules/fastcgi (try also './modules/fastcgi/configure --help')
#   --with-libfcgi-prefix[=DIR]  search for libfcgi in DIR/include and DIR/lib
# * modules/gdbm (try also './modules/gdbm/configure --help')
#   --with-libgdbm-prefix[=DIR]  search for libgdbm in DIR/include and DIR/lib
# * modules/libsvm (try also './modules/libsvm/configure --help')
#   --with-libsvm-prefix[=DIR]  search for libsvm in DIR/include and DIR/lib
# * modules/pari (try also './modules/pari/configure --help')
#   --with-libpari-prefix[=DIR]  search for libpari in DIR/include and DIR/lib
# * modules/pcre (try also './modules/pcre/configure --help')
#   --with-libpcre-prefix[=DIR]  search for libpcre in DIR/include and DIR/lib
# * modules/postgresql (try also './modules/postgresql/configure --help')
#   --with-libpq-prefix[=DIR]  search for libpq in DIR/include and DIR/lib
# * modules/readline (try also './modules/readline/configure --help')
#   --with-libtermcap-prefix[=DIR]
#   --with-libreadline-prefix[=DIR]  search for libreadline in DIR/include and DIR
# /lib
# * modules/zlib (try also './modules/zlib/configure --help')
#   --with-libz-prefix[=DIR]  search for libz in DIR/include and DIR/lib

    cd src
    ./makemake \
        --prefix=/opt/$pkgspec \
        > Makefile

    make config.lisp

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


