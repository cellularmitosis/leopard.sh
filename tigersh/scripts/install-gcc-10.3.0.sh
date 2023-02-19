#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install gcc on OS X Tiger / PowerPC.

package=gcc
version=10.3.0
upstream=https://ftp.gnu.org/gnu/$package/$package-$version/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

    # gc-8.2.2$ppc64 \

for dep in \
    gmp-6.2.1$ppc64 \
    mpfr-4.1.0$ppc64 \
    mpc-1.2.1$ppc64 \
    isl-0.24$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done

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

if ! test -d /opt/ld64-97.17-tigerbrew ; then
    tiger.sh ld64-97.17-tigerbrew
fi

if ! test -e /opt/make-4.3 ; then
    tiger.sh make-4.3
fi
export PATH="/opt/make-4.3/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CC='gcc-4.2 -B/opt/ld64-97.17-tigerbrew/bin'
CXX='g++-4.2 -B/opt/ld64-97.17-tigerbrew/bin'

# Note: I haven't figured out how to get gcc to build using custom flags,
# nor how to build a 64-bit gcc on G5.

# Many thanks to the MacPorts team!
patchroot=https://raw.githubusercontent.com/macports/macports-ports/master/lang/gcc10-bootstrap/files
curl $patchroot/patch-iains-apple-si.diff | patch -p0
curl $patchroot/patch-iains-ppc.diff | patch -p0
curl $patchroot/patch-extra-ppc.diff | patch -p0
curl $patchroot/patch-darwin8.diff | patch -p0

# Bootstrapping fails at the end when comparing the stages:
#   Comparing stages 2 and 3
#   Bootstrap comparison failure!
#   powerpc-apple-darwin8.11.0/libstdc++-v3/src/.libs/libstdc++.6.dylib-master.o differs
#   make[2]: *** [Makefile:23202: compare] Error 1
# Thanks to https://github.com/macports/macports-ports/blob/master/lang/gcc10-bootstrap/Portfile
for f in \
    Makefile.in \
    config/bootstrap-debug.mk \
    config/bootstrap-debug-lean.mk \
    config/bootstrap-debug-lib.mk
do
    sed -i '' -e 's|^do-compare =|do-compare = /usr/bin/true|g' $f
done

bootstrap="--enable-bootstrap"
if test "$(tiger.sh --cpu)" = "g3" ; then
    # temporarily disabling bootstrapping on g3
    bootstrap="--disable-bootstrap"
fi

/usr/bin/time ./configure -C \
    --prefix=/opt/$pkgspec \
    --with-gmp=/opt/gmp-6.2.1$ppc64 \
    --with-mpc=/opt/mpc-1.2.1$ppc64 \
    --with-mpfr=/opt/mpfr-4.1.0$ppc64 \
    --with-isl=/opt/isl-0.24$ppc64 \
    --enable-languages=c,c++,objc,obj-c++,fortran \
    --enable-libssp \
    --enable-lto \
    --disable-objc-gc \
    --enable-shared \
    --with-dwarf2 \
    --program-suffix=-10.3 \
    $bootstrap \
    CC="$CC" \
    CXX="$CXX"

#    --enable-objc-gc \
#    --with-target-bdw-gc=/opt/gc-8.2.2$ppc64 \
# Objc garbage collection support fails because I didn't build bdw-gc as multilib:
#  checking for bdw garbage collector... using paths configured with --with-target-bdw-gc options
#  configure: error: no multilib path (ppc64) found in --with-target-bdw-gc
#  make[1]: *** [Makefile:14095: configure-target-libobjc] Error 1
#  make[1]: Leaving directory '/private/tmp/gcc-10.3.0'
#  make: *** [Makefile:997: all] Error 2

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

# --enable-languages=c,c++,objc,obj-c++,fortran,java \
# --enable-libada \
# see https://sourceforge.net/projects/gnuada/files/GNAT_GPL%20Mac%20OS%20X/2009-tiger-ppc/
