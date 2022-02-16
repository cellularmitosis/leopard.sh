#!/bin/bash
# based on templates/build-from-source.sh v4


# Install git on OS X Leopard / PowerPC.

package=git
version=2.34.1

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    expat-2.4.3$ppc64 \
    libiconv-1.16$ppc64 \
    libressl-3.4.2$ppc64 \
    xz-5.2.5$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done


echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --os.cpu))\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://www.kernel.org/pub/software/scm/$package
    tarball=$package-$version.tar.xz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = f442dade3c73ea39473f6700b3e04dcd

    cd /tmp
    rm -rf $package-$version
    cat ~/Downloads/$tarball | unxz | tar x
    cd $package-$version

    cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache > config.cache

    CFLAGS=$(leopard.sh -mcpu -O)
    if test -n "$ppc64" ; then
        CFLAGS="-m64 $CFLAGS"
        LDFLAGS="-m64 $LDFLAGS"
    fi

    # FIXME despite all of these flags, git is still missing a curl symbol:
    #     LINK git-http-fetch
    # Undefined symbols:
    #   "_curl_global_sslset", referenced from:
    #       _http_init in http.o
    # ld: symbol(s) not found
    # collect2: ld returned 1 exit status
    # make: *** [git-http-fetch] Error 1
    CPPFLAGS="$CPPFLAGS -I/opt/portable-curl-7.58.0-1/include"
    LDFLAGS="$LDFLAGS -L/opt/portable-curl-7.58.0-1/lib"
    LIBS="$LIBS -lcurl"

        ./configure -C --prefix=/opt/$pkgspec \
            --with-openssl=/opt/libressl-3.4.2$ppc64 \
            --with-curl=/opt/portable-curl-7.58.0-1 \
            --with-iconv=/opt/libiconv-1.16$ppc64 \
            --with-expat=/opt/expat-2.4.3$ppc64 \
            CFLAGS="$CFLAGS" \
            CPPFLAGS="$CPPFLAGS" \
            LDFLAGS="$LDFLAGS" \
            LIBS="$LIBS"

    make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        # FIXME some tests need a recent python.
        make check
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
