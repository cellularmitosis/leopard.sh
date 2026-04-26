#!/bin/bash
# based on templates/build-from-source.sh v6

# 👇 EDIT HERE:
# Install foo on OS X Leopard / PowerPC.

# 👇 EDIT HERE:
package=emacs
version=29.1
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz
# upstream=https://downloads.sourceforge.net/$package/$package-$version.tar.gz
description="An operating system in need of a good editor"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# 👇 EDIT HERE:
if ! test -e /opt/gcc-4.9.4 ; then
    leopard.sh gcc-libs-4.9.4
fi

# 👇 EDIT HERE:
# dep=bar-1.0$ppc64
# if ! test -e /opt/$dep ; then
#     leopard.sh $dep
#     PATH="/opt/$dep/bin:$PATH"
# fi

# 👇 EDIT HERE:
for dep in \
    libpng-1.6.40$ppc64 \
    libwebp-1.3.1$ppc64 \
    sqlite3-3.40.1$ppc64 \
    libxml2-2.9.12$ppc64 \
    freetype-2.13.0$ppc64 \
    gnutls-3.7.10$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    # CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    # LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
    # PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
done
# LIBS="-lbar -lqux"
# PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"

for dep in \
    libjpeg-6b$ppc64 \
    libtiff-4.5.1$ppc64 \
    libgif-5.2.1$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done

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

# 👇 EDIT HERE:
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
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/X11/lib/pkgconfig"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

patch -p0 << 'EOF'
--- configure.orig	2023-09-02 14:49:58.000000000 -0500
+++ configure	2023-09-02 14:51:13.000000000 -0500
@@ -6109,8 +6109,8 @@
   ## Apple Darwin / macOS
   *-apple-darwin* )
     case "${canonical}" in
-      *-apple-darwin[0-9].*) unported=yes ;;
-      i[3456]86-* | x86_64-* | arm-* | aarch64-* )  ;;
+      *-apple-darwin[0-7].*) unported=yes ;;
+      i[3456]86-* | x86_64-* | arm-* | aarch64-* | powerpc-* )  ;;
       * )            unported=yes ;;
     esac
     opsys=darwin
EOF

for f in configure lwlib/lwlib-Xaw.c lwlib/lwlib.c src/xfns.c src/xmenu.c src/xterm.c ; do
    sed -i '' -e 's|#include <X11/Xaw3d/|#include <X11/Xaw/|g' $f
done

for f in configure  ; do
    sed -i '' -e 's|-lXaw3d|-lXaw|g' $f
done

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
    --without-ns \
    --with-x \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CC="$CC" \
    CXX="$CXX" \
    OBJC="$OBJC" \
    # --with-bar=/opt/bar-1.0$ppc64 \
    # --with-bar-prefix=/opt/bar-1.0$ppc64 \
    # LIBS="$LIBS" \
    # PKG_CONFIG=/opt/pkg-config-0.29.2/bin/pkg-config \
    # PKG_CONFIG_PATH="/opt/libfoo-1.0$ppc64/lib/pkgconfig:/opt/libbar-1.0$ppc64/lib/pkgconfig" \

# error: unknown type name 'XRRScreenResources'
sed -i '' -e 's|#define HAVE_XRANDR 1|#undef HAVE_XRANDR|' src/config.h

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
