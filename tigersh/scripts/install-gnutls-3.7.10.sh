#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install gnutls on OS X Tiger / PowerPC.

package=gnutls
version=3.7.10
upstream=https://www.gnupg.org/ftp/gcrypt/gnutls/v3.7/gnutls-$version.tar.xz
description="A secure communications library implementing the SSL, TLS and DTLS protocols"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gcc-4.9.4 ; then
    tiger.sh gcc-libs-4.9.4
fi

dep=nettle-3.9.1$ppc64
if ! test -e /opt/$dep ; then
    tiger.sh $dep
fi
PATH="/opt/$dep/bin:$PATH"
CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
LDFLAGS="-L/opt/$dep/lib $LDFLAGS"

dep=gmp-6.2.1$ppc64
if ! test -e /opt/$dep ; then
    tiger.sh $dep
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
#         tiger.sh $dep
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

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if test -z "$ppc64" -a "$(tiger.sh --cpu)" = "g5" ; then
    # Fails during a 32-bit build on a G5 machine,
    # so we instead install the g4e binpkg in that case.
    if tiger.sh --install-binpkg $pkgspec tiger.g4e ; then
        exit 0
    fi
else
    if tiger.sh --install-binpkg $pkgspec ; then
        exit 0
    fi
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

# 👇 EDIT HERE:
# if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
#     tiger.sh gcc-4.2
# fi
# CC=gcc-4.2
# OBJC=gcc-4.2
# CXX=g++-4.2

if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
fi
CC=gcc-4.9
OBJC=gcc-4.9
CXX=g++-4.9

# 👇 EDIT HERE:
# if ! test -e /opt/ld64-97.17-tigerbrew ; then
#     tiger.sh ld64-97.17-tigerbrew
# fi
# export PATH="/opt/ld64-97.17-tigerbrew/bin:$PATH"
# CC='gcc -B/opt/ld64-97.17-tigerbrew/bin'
# OBJC='gcc -B/opt/ld64-97.17-tigerbrew/bin'
# CXX='gxx -B/opt/ld64-97.17-tigerbrew/bin'

# 👇 EDIT HERE:
if ! type -a pkg-config >/dev/null 2>&1 ; then
    tiger.sh pkg-config-0.29.2
fi
export PATH="/opt/pkg-config-0.29.2/bin:$PATH"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
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

patch -p0 << 'EOF'
--- lib/system/certs.c.orig	2023-09-02 18:04:00.000000000 -0500
+++ lib/system/certs.c	2023-09-02 18:05:05.000000000 -0500
@@ -47,7 +47,7 @@
 #ifdef __APPLE__
 # include <CoreFoundation/CoreFoundation.h>
 # include <Security/Security.h>
-# include <Availability.h>
+# include <AvailabilityMacros.h>
 #endif
 
 /* System specific function wrappers for certificate stores.
@@ -276,7 +276,7 @@
 
 	return r;
 }
-#elif defined(__APPLE__) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 1070
+#elif defined(__APPLE__) && defined(MAC_OS_X_VERSION_10_7)
 static
 int osstatus_error(status)
 {
EOF

# 👇 EDIT HERE:
CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(tiger.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
    CPPFLAGS="$CPPFLAGS -D__WORDSIZE=64"
else
    CFLAGS="$(tiger.sh -m32) $CFLAGS"
    # On Tiger, SIZE_MAX is set to 2^32 even on G5 with -m64, causing compilation problems.
    # Thanks to https://github.com/macports/macports-ports/blob/master/devel/gnutls/Portfile
    if test "$(tiger.sh --cpu)" = "g5" ; then
        CPPFLAGS="$CPPFLAGS -D__WORDSIZE=32"
        # Despite the above "fix", SIZE_MAX still causes the build to blow up on G5's.
        # Instead, we just install the G4 package on G5's.
        exit 1
    fi
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
    # OBJC="$CC" \
    # PKG_CONFIG=/opt/pkg-config-0.29.2/bin/pkg-config \
    # PKG_CONFIG_PATH="/opt/libfoo-1.0$ppc64/lib/pkgconfig:/opt/libbar-1.0$ppc64/lib/pkgconfig" \

/usr/bin/time make $(tiger.sh -j) V=1

# 👇 EDIT HERE:
if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
# if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
#     make check
# fi

# 👇 EDIT HERE:
# if test -n "$TIGERSH_RUN_LONG_TESTS" ; then
#     make check
# fi

# 👇 EDIT HERE:
# Note: no 'make check' available.

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
