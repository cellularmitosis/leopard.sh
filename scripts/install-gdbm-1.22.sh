#!/bin/bash

# Install gdbm on OS X Leopard / PowerPC.

package=gdbm
version=1.22

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if ! test -e /opt/libiconv-1.16; then
    leopard.sh libiconv-1.16
fi

if ! test -e /opt/gettext-0.21; then
    leopard.sh gettext-0.21
fi

if ! test -e /opt/readline-8.1.2; then
    leopard.sh readline-8.1.2
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version
    CPPFLAGS=-I/opt/readline-8.1.2/include \
    LDFLAGS=-L/opt/readline-8.1.2/lib \
        ./configure -C --prefix=/opt/$package-$version \
            --with-libiconv-prefix=/opt/libiconv-1.16 \
            --with-libintl-prefix=/opt/gettext-0.21 \
            --with-readline
    make $(leopard.sh -j)

    if test -n "$LEOPARDSH_RUN_TESTS"; then
        make check
    fi

    make install
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/

# input-rl.c: In function 'instream_readline_history_get':
# input-rl.c:194: error: subscripted value is neither array nor pointer
