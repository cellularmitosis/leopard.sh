#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install SBCL on OS X Tiger / PowerPC.

package=sbcl
version=2.0.9
upstream=https://downloads.sourceforge.net/$package/$package-$version-source.tar.bz2
description="Steel Bank Common Lisp"

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

# 👇 EDIT HERE:
# dep=bar-1.0$ppc64
# if ! test -e /opt/$dep ; then
#     tiger.sh $dep
#     PATH="/opt/$dep/bin:$PATH"
# fi

# Tiger needs _SC_NPROCESSORS_ONLN:
# gcc-4.9 -Wall -Os -fdollars-in-identifiers -mmacosx-version-min=10.4 -I../src/runtime   grovel-headers.c  -lSystem -lc -lgcc -o grovel-headers
# grovel-headers.c: In function 'main':
# grovel-headers.c:253:40: error: '_SC_NPROCESSORS_ONLN' undeclared (first use in this function)
#      defconstant("sc-nprocessors-onln", _SC_NPROCESSORS_ONLN);
dep=macports-legacy-support-20221029$ppc64
if ! test -e /opt/$dep ; then
    tiger.sh $dep
fi
CPPFLAGS="-I/opt/$dep/include/LegacySupport $CPPFLAGS"
LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
LIBS="-lMacportsLegacySupport"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

# An older version of SBCL is needed to perform the build.
if ! type -a sbcl >/dev/null 2>&1 ; then
    tiger.sh sbcl-1.0.47
fi

# We need gcc-4.9:
# /usr/libexec/gcc/powerpc-apple-darwin8/4.0.1/ld: Undefined symbols:
# ___sync_fetch_and_and
# ___sync_fetch_and_or
# ___sync_fetch_and_add
# collect2: ld returned 1 exit status
# make: *** [sbcl] Error 1
if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
fi
CC=gcc-4.9

# Tiger's expr is too old:
#   expr: brackets ([ ]) not balanced
#   Malformed feature toggle: --with-sb-core-compression
#   Enter "make-config.sh --help" for list of valid options.
if ! test -e /opt/coreutils-9.0 ; then
    tiger.sh coreutils-9.0
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

for f in src/runtime/Config.ppc-darwin ; do
    sed -i '' -e 's/ -g //' $f
    sed -i '' -e "s| -O2 | $(tiger.sh -mcpu -O) $CPPFLAGS $LDFLAGS |" $f
    sed -i '' -e "s|OS_LIBS = -lSystem -lc|OS_LIBS = -lSystem -lc -lgcc $LDFLAGS $LIBS |" $f
    sed -i '' -e 's/CPPFLAGS += -no-cpp-precomp/#CPPFLAGS += -no-cpp-precomp/' $f
    sed -i '' -e 's/CC = gcc/CC = gcc-4.9/' $f
done

sed -i '' -e 's|`expr|`/opt/coreutils-9.0/bin/expr|g' make-config.sh

/usr/bin/time ./make.sh --prefix=/opt/$pkgspec \
    --with-sb-core-compression

    # --with-sb-thread
# Threads are unavailable:
# ppc-darwin-os.c:28:2: error: #error "Define threading support functions"
#  #error "Define threading support functions"
#   ^
# gcc-4.9 -Wall -Os -fdollars-in-identifiers -mmacosx-version-min=10.5 -I.  -c -o alloc.o alloc.c
# In file included from target-os.h:88:0,
#                  from os.h:59,
#                  from globals.h:19,
#                  from thread.h:8,
#                  from gc-internal.h:28,
#                  from alloc.h:17,
#                  from alloc.c:17:
# darwin-os.h:41:31: fatal error: dispatch/dispatch.h: No such file or directory
#  #include <dispatch/dispatch.h>

# TODO: make a tex package and install the docs.
#cd doc/manual
#make
#cd - >/dev/null

if test -n "$TIGERSH_RUN_LONG_TESTS" ; then
    cd tests
    sh run-tests.sh
    cd - >/dev/null
fi

INSTALL_ROOT=/opt/$pkgspec ./install.sh

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
