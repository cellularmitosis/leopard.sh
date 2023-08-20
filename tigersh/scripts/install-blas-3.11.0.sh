#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install BLAS on OS X Tiger / PowerPC.

package=blas
version=3.11.0
upstream=http://www.netlib.org/$package/$package-$version.tgz
description="Basic Linear Algebra Subprograms"

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

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

FLAGS="$(tiger.sh -mcpu -O) -fPIC"
if test -n "$ppc64" ; then
    FLAGS="-m64 $FLAGS"
fi

# Thanks to https://bizhishui.github.io/Build-Netlib
# Build a shared lib.
gfortran-4.9 $FLAGS -shared *.f *.f90 -o libblas.dylib
# Build a static lib.
gfortran-4.9 $FLAGS -c *.f *.f90
ar cr libblas.a *.o

if test -n "$TIGERSH_RUN_TESTS" ; then
    cd TESTING
    make run FC=gfortran-4.9 PLAT=''
    cd -
    make check
fi

mkdir -p /opt/$pkgspec/lib
ln -s libblas.a blas.a
mv libblas.dylib libblas.a blas.a /opt/$pkgspec/lib/

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
