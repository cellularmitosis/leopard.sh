#!/bin/bash
# based on templates/build-from-source.sh v6

# Install ld64 on OS X Leopard / PowerPC.

package=ld64
version=97.17
upstream=https://opensource.apple.com/tarballs/ld64/ld64-97.17.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

url=https://trac.macports.org/export/123511/trunk/dports/devel/ld64/files/Makefile-97
curl --fail --silent --show-error --location --remote-name $url
test "$(md5 -q Makefile-97)" = "85c3822b18d8d1bb0793165bf8927e78"
mv Makefile-97 Makefile

for p in \
    "ld64-97-ppc-branch-island.patch c26672d1f6cccbbbff48dfe06bb78ac7" \
    "ld64-97-no-LTO.patch 901973aaa278fca34418c5240a092f13" \
    "ld64-version.patch 2f3d563be15053a416846922bee08e3d"
; do
    p=$(echo $p | cut -d' ' -f1)
    m=$(echo $p | cut -d' ' -f2)
    url=https://trac.macports.org/export/103948/trunk/dports/devel/ld64/files/$p
    curl --fail --silent --show-error --location --remote-name $url
    test "$(md5 -q $p)" = "$m"
    patch -p0 < $p
done

leopard.sh --unpack-dist xnu-1504.15.3  # from Snow Leopard 10.6.8
leopard.sh --unpack-dist libunwind-30  # from Lion 10.7.5
(cd /tmp/libunwind-30 && ln -s src libunwind)
leopard.sh --unpack-dist dyld-132.13  # from Snow Leopard 10.6.8

/usr/bin/time make \
    $(leopard.sh -j) \
    CC=gcc-4.9 CXX=g++-4.9 \
    CPPFLAGS="-Isrc/abstraction -Isrc/ld -I/tmp/xnu-1504.15.3/EXTERNAL_HEADERS -I/tmp/libunwind-30 -I/tmp/libunwind-30/include -I/tmp/dyld-132.13/include"

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

# Note: no 'make check' available.

make install PREFIX=/opt/$pkgspec

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
