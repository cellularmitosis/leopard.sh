#!/bin/bash
# based on templates/build-from-source.sh v6

# Install mplayer on OS X Leopard / PowerPC.

package=mplayer
version=1.5
upstream=https://mplayerhq.hu/MPlayer/releases/MPlayer-$version.tar.gz
description="Movie player for Unix-like systems"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    gettext-0.21$ppc64 \
    pcre2-10.42$ppc64 \
    libffi-3.4.2$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    # CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    # LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    # PATH="/opt/$dep/bin:$PATH"
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
done
# LIBS="-lbar -lqux"
PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"

if ! test -e /opt/mplayer-binary-codecs-20041107 ; then
    leopard.sh mplayer-binary-codecs-20041107
fi

if ! test -e /opt/gcc-4.9.4 ; then
    leopard.sh gcc-libs-4.9.4
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

if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9.4
fi
CC=gcc-4.9
CXX=g++-4.9
OBJC=gcc-4.9

if ! which -s pkg-config ; then
    leopard.sh pkg-config-0.29.2
fi
export PATH="/opt/pkg-config-0.29.2/bin:$PATH"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

/usr/bin/time \
    env CC="$CC" CXX="$CXX" \
    ./configure --prefix=/opt/$pkgspec \
    --codecsdir="/opt/mplayer-binary-codecs-20041107/lib/codecs" \
    --enable-openssl-nondistributable \
    --enable-macosx-finder \
    --enable-macosx-bundle \
    --extra-cflags="$CPPFLAGS" \
    --extra-ldflags="$LDFLAGS" \
    --extra-libs-mplayer="$LIBS" \
    --extra-libs-mencoder="$LIBS" \
    | tee /tmp/mplayer.log

/usr/bin/time make $(leopard.sh -j) V=1

# Note: no 'make check' available.

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
