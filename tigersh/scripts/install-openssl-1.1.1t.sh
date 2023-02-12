#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install openssl on OS X Tiger / PowerPC.

package=openssl
version=1.1.1t
upstream=https://www.openssl.org/source/$package-$version.tar.gz
description="Secure Sockets Layer library and cryptographic utilities."

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/ca-certificates-20230110 ; then
    tiger.sh ca-certificates-20230110
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.2
fi

# Configure needs a more recent perl.
# $ ./Configure --help
# Perl v5.10.0 required--this is only v5.8.6, stopped at ./Configure line 12.
# BEGIN failed--compilation aborted at ./Configure line 12.
if ! test -e /opt/perl-5.36.0 ; then
    tiger.sh perl-5.36.0
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Availability.h wasn't available until Leopard.
#   In file included from crypto/init.c:13:
#   include/crypto/rand.h:24:28: error: Availability.h: No such file or directory
#   make[1]: *** [crypto/init.o] Error 1
# Convert the preprocessor logic to AvailabilityMacros.h style:
sed -i '' -e 's/<Availability.h>/<AvailabilityMacros.h>/' include/crypto/rand.h
sed -i '' -e 's/(defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101200)/defined(MAC_OS_X_VERSION_10_12)/' include/crypto/rand.h

# Note: The 'async' Configure option causes a build failure:
#   ld: Undefined symbols:
#   _getcontext
#   _makecontext
#   _setcontext
# These functions are from ucontext.h and weren't introduced until Leopard,
# to we use no-async.

PATH="/opt/perl-5.36.0/bin:$PATH" \
    ./Configure --prefix=/opt/openssl-1.1.1t \
        threads \
        shared \
        no-async \
        darwin-ppc-cc

PATH="/opt/perl-5.36.0/bin:$PATH" \
    /usr/bin/time make $(tiger.sh -j)

# Note: no 'make check' available.

PATH="/opt/perl-5.36.0/bin:$PATH" \
    make install

ln -s /opt/ca-certificates-20230110/share/cacert.pem /opt/$pkgspec/ssl/cert.pem

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
