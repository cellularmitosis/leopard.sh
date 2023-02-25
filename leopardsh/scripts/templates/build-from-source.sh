#!/bin/bash
# based on templates/build-from-source.sh v6

# 👇 EDIT HERE:
# Install foo on OS X Leopard / PowerPC.

# 👇 EDIT HERE:
package=foo
version=1.0
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz
upstream=https://sourceforge.net/projects/$package/files/$package/$version/$package-$version.tar.gz/download
description="FIXME"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# 👇 EDIT HERE:
# if ! test -e /opt/bar-2.0$ppc64 ; then
#     leopard.sh bar-2.0$ppc64
#     PATH="/opt/bar-2.0$ppc64/bin:$PATH"
# fi

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
# done
# LIBS="-lbar -lqux"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

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

# 👇 EDIT HERE:
# if ! which -s gcc-4.9 ; then
#     leopard.sh gcc-4.9.4
# fi

# 👇 EDIT HERE:
# if ! which -s gcc-10.3 ; then
#     leopard.sh gcc-10.3.0
# fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# 👇 EDIT HERE:
# CC=gcc-4.2
# CXX=g++-4.2

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
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    # --with-bar=/opt/bar-1.0 \
    # --with-bar-prefix=/opt/bar-1.0 \
    # LDFLAGS="$LDFLAGS" \
    # CPPFLAGS="$CPPFLAGS" \
    # LIBS="$LIBS" \
    # CC="$CC" \
    # CXX="$CXX"

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
