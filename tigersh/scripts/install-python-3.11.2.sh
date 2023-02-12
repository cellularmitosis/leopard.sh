#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install python on OS X Tiger / PowerPC.

# FIXME: this is just a bare-minimum python build.  get ssl working.

package=python
version=3.11.2
upstream=https://www.python.org/ftp/python/$version/Python-$version.tgz
description="An interpreted, interactive, object-oriented programming language"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
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

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Many thanks to the MacPorts team!
for triple in \
    "-p0 patch-setup.py.diff 0036648697b52bf335cf3b953a06292f" \
    "-p0 patch-Lib-cgi.py.diff 46927f93e99c7226553627e1ab8a4e2a" \
    "-p0 patch-configure.diff 05d083c703c411a400f994bcd1b193c1" \
    "-p0 patch-Lib-ctypes-macholib-dyld.py.diff 7590aab5132d3b70b4a7d1980c4d3a56" \
    "-p0 sysconfig.py.patch c1f459a3c809af606f81378caa73c45d" \
    "-p0 static_assert.patch d456ae0da65b11fbf3f7ab33c6bf3bcc" \
    "-p0 patch-no-copyfile-on-Tiger.diff 26274b5a66846bffaf35b0ea951afde8" \
    "-p0 patch-threadid-older-systems.diff 02c3f4bac14fef79e7ecae1af45a1f72" \
; do
    plevel=$(echo $triple | cut -d' ' -f1)
    pfile=$(echo $triple | cut -d' ' -f2)
    sum=$(echo $triple | cut -d' ' -f3)
    url=https://raw.githubusercontent.com/macports/macports-ports/master/lang/python311/files/$pfile
    curl --fail --silent --show-error --location --remote-name $url
    test "$(md5 -q $pfile)" = "$sum"
    patch $plevel < $pfile
done

CC=gcc-4.9

# CFLAGS=$(tiger.sh -mcpu -O)
CFLAGS="-O0"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# Thanks to https://trac.macports.org/ticket/66483
LDFLAGS="$LDFLAGS -Wl,-read_only_relocs,suppress"

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \
    OPT="-O0" \
    CC="$CC"

    # --enable-optimizations

# With gcc-4.9, the build fails with:
#   gcc-4.9 -c  -DNDEBUG -g -fwrapv -O3 -Wall -mcpu=7450 -O2   -std=c11 -Werror=implicit-function-declaration -fvisibility=hidden  -I./Include/internal  -I. -I./Include    -DPy_BUILD_CORE -o Objects/longobject.o Objects/longobject.c
#   Objects/longobject.c: In function 'bit_length_digit':
#   Objects/longobject.c:779:5: error: implicit declaration of function 'static_assert' [-Werror=implicit-function-declaration]
#        static_assert(PyLong_SHIFT <= sizeof(unsigned long) * 8,
#        ^
#   cc1: some warnings being treated as errors
#   make: *** [Objects/longobject.o] Error 1
#
# There is already a work-around for this in pymacro.h, but it is only defined
# for glibc.  So we do the same for __APPLE__.
cat >> Include/pymacro.h << 'EOF'

// In C++ 11 static_assert is a keyword, redefining is undefined behaviour.
#if defined(__APPLE__) \
     && !(defined(__cplusplus) && __cplusplus >= 201103L) \
     && !defined(static_assert)
#  define static_assert _Static_assert
#endif
EOF

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
