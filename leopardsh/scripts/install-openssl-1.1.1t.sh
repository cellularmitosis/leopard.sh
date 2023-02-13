#!/bin/bash
# based on templates/build-from-source.sh v6

# Install openssl on OS X Leopard / PowerPC.

package=openssl
version=1.1.1t
upstream=https://www.openssl.org/source/$package-$version.tar.gz
description="Secure Sockets Layer library and cryptographic utilities."

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/ca-certificates-20230110 ; then
    leopard.sh ca-certificates-20230110
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
fi

# Configure needs a more recent perl.
# $ ./Configure --help
# Perl v5.10.0 required--this is only v5.8.6, stopped at ./Configure line 12.
# BEGIN failed--compilation aborted at ./Configure line 12.
if ! test -e /opt/perl-5.36.0 ; then
    leopard.sh perl-5.36.0
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    target=darwin64-ppc-cc
else
    target=darwin-ppc-cc
fi

PATH="/opt/perl-5.36.0/bin:$PATH" \
    ./Configure --prefix=/opt/$pkgspec \
        threads \
        shared \
        $target \
        CFLAGS="$CFLAGS"

PATH="/opt/perl-5.36.0/bin:$PATH" \
    /usr/bin/time make $(leopard.sh -j)

# Note: no 'make check' available.

PATH="/opt/perl-5.36.0/bin:$PATH" \
    make install

ln -s /opt/ca-certificates-20230110/share/cacert.pem /opt/$pkgspec/ssl/cert.pem

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
