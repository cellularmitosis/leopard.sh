#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install autogen on OS X Tiger / PowerPC.

package=autogen
version=5.18.16
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz
description="Automated text file generator"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    guile-2.0.14$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done
# LIBS="-lbar -lqux"

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

if ! test -e /opt/pkg-config-0.29.2 ; then
    tiger.sh pkg-config-0.29.2
fi

# configure failure:
#   config.status: executing depfiles commands
#   config.status: error: in `/tmp/autogen-5.18.16':
#   config.status: error: Something went wrong bootstrapping makefile fragments
#       for automatic dependency tracking.  Try re-running configure with the
#       '--disable-dependency-tracking' option to at least be able to build
#       the package (albeit without support for automatic dependency tracking).
#   See `config.log' for more details
#
# The config.log is full of this:
#   mktemp: illegal option -- -
#   usage: mktemp [-d] [-q] [-t prefix] [-u] template ...
#          mktemp [-d] [-q] [-u] -t prefix 
#
# So we pull in mktemp from coreutils and use that instead.
if ! test -e /opt/coreutils-9.0 ; then
    tiger.sh coreutils-9.0
fi
export PATH="/opt/coreutils-9.0/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CC=gcc-4.2
CXX=g++-4.2

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# Looks like gcc-4.2 is too old to recognize this option:
# libtool: compile:  gcc -std=gnu99 -DHAVE_CONFIG_H -I. -I.. -I.. -I/opt/guile-2.0.14/include -mcpu=970 -O2 -Wno-format-contains-nul -fno-strict-aliasing -c snv.c  -fno-common -DPIC -o .libs/snv.o
# cc1: error: unrecognized command line option "-Wno-format-contains-nul"

patch -p0 << 'EOF'
--- configure	2018-08-26 09:44:54.000000000 -0800
+++ configure.patched	2023-02-17 20:09:31.000000000 -0900
@@ -18923,8 +18923,8 @@
 
 WARN_CFLAGS=
 test "X${GCC}" = Xyes && {
-  CFLAGS="$CFLAGS -Wno-format-contains-nul -fno-strict-aliasing"
-  WARN_CFLAGS="$CFLAGS "`echo -Wall -Werror -Wcast-align -Wmissing-prototypes \
+  CFLAGS="$CFLAGS -fno-strict-aliasing"
+  WARN_CFLAGS="$CFLAGS "`echo -Wall -Wcast-align -Wmissing-prototypes \
 	-Wpointer-arith -Wshadow -Wstrict-prototypes -Wwrite-strings \
 	-Wstrict-aliasing=3 -Wextra -Wno-cast-qual`
 }
EOF

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \
    PKG_CONFIG="/opt/pkg-config-0.29.2/bin/pkg-config" \
    PKG_CONFIG_PATH="/opt/guile-2.0.14$ppc64/lib/pkgconfig" \
    CC="$CC" \
    CXX="$CXX"

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
