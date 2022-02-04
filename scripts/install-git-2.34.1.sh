#!/bin/bash

# Install git on OS X Leopard / PowerPC.

package=git
version=2.34.1

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if ! which -s xz; then
    leopard.sh xz-5.2.5
fi

if ! test -e /opt/libressl-3.4.2; then
    leopard.sh libressl-3.4.2
fi

if ! test -e /opt/libiconv-1.16; then
    leopard.sh libiconv-1.16
fi

if ! test -e /opt/expat-2.4.3; then
    leopard.sh expat-2.4.3
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://www.kernel.org/pub/software/scm/$package
    tarball=$package-$version.tar.xz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    cat ~/Downloads/$tarball | unxz | tar x
    cd $package-$version
    # FIXME despite all of these flags, git is still missing a curl symbol:
    #     LINK git-http-fetch
    # Undefined symbols:
    #   "_curl_global_sslset", referenced from:
    #       _http_init in http.o
    # ld: symbol(s) not found
    # collect2: ld returned 1 exit status
    # make: *** [git-http-fetch] Error 1
    CPPFLAGS=-I/opt/portable-curl-7.58.0-1/include \
    LDFLAGS=-L/opt/portable-curl-7.58.0-1/lib \
    LIBS=-lcurl \
        ./configure -C --prefix=/opt/$package-$version \
            --with-openssl=/opt/libressl-3.4.2 \
            --with-curl=/opt/portable-curl-7.58.0-1 \
            --with-iconv=/opt/libiconv-1.16 \
            --with-expat=/opt/expat-2.4.3
    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS"; then
        # FIXME some tests need a recent python.
        make check
    fi

    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/
