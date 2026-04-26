#!/bin/bash
# based on templates/build-from-source.sh v6

# Install gnutls on OS X Leopard / PowerPC.

package=gnutls
version=3.7.10
upstream=https://www.gnupg.org/ftp/gcrypt/gnutls/v3.7/gnutls-$version.tar.xz
description="A secure communications library implementing the SSL, TLS and DTLS protocols"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gcc-4.9.4 ; then
    leopard.sh gcc-libs-4.9.4
fi

dep=nettle-3.9.1$ppc64
if ! test -e /opt/$dep ; then
    leopard.sh $dep
fi
PATH="/opt/$dep/bin:$PATH"
CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
LDFLAGS="-L/opt/$dep/lib $LDFLAGS"

dep=gmp-6.2.1$ppc64
if ! test -e /opt/$dep ; then
    leopard.sh $dep
fi
PATH="/opt/$dep/bin:$PATH"
CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
LDFLAGS="-L/opt/$dep/lib $LDFLAGS"

# 👇 EDIT HERE:
# for dep in \
#     bar-2.1$ppc64 \
#     qux-3.4$ppc64
# do
#     if ! test -e /opt/$dep ; then
#         leopard.sh $dep
#     fi
#     CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
#     LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
#     PATH="/opt/$dep/bin:$PATH"
#     PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
# done
# LIBS="-lbar -lqux"
# PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"

# 👇 EDIT HERE:
# if ! perl -e "use Text::Unidecode" >/dev/null 2>&1 ; then
#     echo no | cpan
#     cpan Text::Unidecode
# fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

# 👇 EDIT HERE:
# if test -z "$ppc64" -a "$(leopard.sh --cpu)" = "g5" ; then
#     # Fails during a 32-bit build on a G5 machine,
#     # so we instead install the g4e binpkg in that case.
#     if leopard.sh --install-binpkg $pkgspec leopard.g4e ; then
#         exit 0
#     fi
# else
#     if leopard.sh --install-binpkg $pkgspec ; then
#         exit 0
#     fi
# fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

# 👇 EDIT HERE:
# if ! which -s gcc-4.2 ; then
#     leopard.sh gcc-4.2
# fi
# CC=gcc-4.2
# OBJC=gcc-4.2
# CXX=g++-4.2

if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9.4
fi
CC=gcc-4.9
OBJC=gcc-4.9
CXX=g++-4.9

# 👇 EDIT HERE:
# if ! test -e /opt/ld64-97.17-tigerbrew ; then
#     leopard.sh ld64-97.17-tigerbrew
# fi
# export PATH="/opt/ld64-97.17-tigerbrew/bin:$PATH"
# CC='gcc -B/opt/ld64-97.17-tigerbrew/bin'
# OBJC='gcc -B/opt/ld64-97.17-tigerbrew/bin'
# CXX='gxx -B/opt/ld64-97.17-tigerbrew/bin'

# 👇 EDIT HERE:
if ! which -s pkg-config ; then
    leopard.sh pkg-config-0.29.2
fi
export PATH="/opt/pkg-config-0.29.2/bin:$PATH"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# We use nettle's built-in mini-gmp 
# patch -p0 << 'EOF'
# --- configure.orig	2023-09-02 16:19:10.000000000 -0500
# +++ configure	2023-09-02 16:19:22.000000000 -0500
# @@ -8872,7 +8872,7 @@
#    rpathdirs=
#    ltrpathdirs=
#    names_already_handled=
# -  names_next_round='nettle hogweed gmp'
# +  names_next_round='nettle hogweed'
#    while test -n "$names_next_round"; do
#      names_this_round="$names_next_round"
#      names_next_round=
# EOF

# 👇 EDIT HERE:
CFLAGS="$(leopard.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(leopard.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# 👇 EDIT HERE:
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --with-included-libtasn1 \
    --with-included-unistring \
    --without-p11-kit \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CC="$CC" \
    CXX="$CXX" \
    # --with-bar=/opt/bar-1.0$ppc64 \
    # --with-bar-prefix=/opt/bar-1.0$ppc64 \
    # LIBS="$LIBS" \
    # OBJC="$OBJC" \
    # PKG_CONFIG=/opt/pkg-config-0.29.2/bin/pkg-config \
    # PKG_CONFIG_PATH="/opt/libfoo-1.0$ppc64/lib/pkgconfig:/opt/libbar-1.0$ppc64/lib/pkgconfig" \

/usr/bin/time make $(leopard.sh -j) V=1

# 👇 EDIT HERE:
if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
# if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
#     make check
# fi

# 👇 EDIT HERE:
# if test -n "$LEOPARDSH_RUN_LONG_TESTS" ; then
#     make check
# fi

# 👇 EDIT HERE:
# Note: no 'make check' available.

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
