#!/bin/bash
# based on templates/build-from-source.sh v6

# Install llvm on OS X Leopard / PowerPC.

# From https://github.com/macports/macports-ports/blob/master/lang/llvm-3.7/Portfile:
#   llvm-3.7 was the last version to use the autoconf build system.  Newer
#   versions require cmake to build.  Cmake requires a C++11 toolchain, so
#   clang-3.7 is being kept around in order to build cmake (or its dependencies)
#   if needed on such systems.

package=llvm
version=3.7.1
upstream=https://releases.llvm.org/3.7.1/llvm-3.7.1.src.tar.xz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/libffi-3.4.2 ; then
    leopard.sh libffi-3.4.2
fi

if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9.4
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

if ! test -e /opt/python2-2.7.18 ; then
    leopard.sh python2-2.7.18
fi

if ! test -e /opt/ld64-97.17-tigerbrew ; then
    leopard.sh ld64-97.17-tigerbrew
fi
export PATH="/opt/ld64-97.17/bin:$PATH"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

leopard.sh --unpack-dist cfe-3.7.1.src
mv /tmp/cfe-3.7.1.src /tmp/$package-$version/tools/clang

leopard.sh --unpack-dist libcxx-3.7.1.src
mv /tmp/libcxx-3.7.1.src /tmp/$package-$version/projects/libcxx

leopard.sh --unpack-dist libcxxabi-3.7.1.src
mv /tmp/libcxxabi-3.7.1.src /tmp/$package-$version/libcxxabi

# leopard.sh --unpack-dist polly-3.7.1.src
# mv /tmp/polly-3.7.1.src /tmp/$package-$version/tools/polly

# leopard.sh --unpack-dist clang-tools-extra-3.7.1.src
# mv /tmp/clang-tools-extra-3.7.1.src /tmp/$package-$version/tools/clang/tools/extra

# leopard.sh --unpack-dist compiler-rt-3.7.1.src
# mv /tmp/compiler-rt-3.7.1.src /tmp/$package-$version/projects/compiler-rt

# leopard.sh --unpack-dist lld-3.7.1.src
# mv /tmp/lld-3.7.1.src /tmp/$package-$version/tools/lld

# leopard.sh --unpack-dist lldb-3.7.1.src
# mv /tmp/lldb-3.7.1.src /tmp/$package-$version/tools/lldb

for pair in \
    "1006-Only-call-setpriority-PRIO_DARWIN_THREAD-0-PRIO_DARW.patch ccdf219c313120ef149adf05c6ff2da1" \
; do
    pfile=$(echo $pair | cut -d' ' -f1)
    sum=$(echo $pair | cut -d' ' -f2)
    url=https://raw.githubusercontent.com/macports/macports-ports/master/lang/llvm-3.7/files/$pfile
    curl --fail --silent --show-error --location --remote-name $url
    test "$(md5 -q $pfile)" = "$sum"
    patch -p1 < $pfile
done

CC=gcc-4.9
CXX=g++-4.9

builddir=/tmp/$pkgspec.build
rm -rf $builddir
mkdir $builddir
cd $builddir

/usr/bin/time /tmp/$package-$version/configure -C --prefix=/opt/$pkgspec \
    --with-python=/opt/python2-2.7.18/bin/python2 \
    --enable-targets=powerpc \
    --enable-optimized \
    --with-optimize-option=" -O0" \
    --disable-bindings \
    CC="$CC" \
    CXX="$CXX"

    # --enable-shared \
    # --disable-assertions
    # --with-optimize-option=" $(leopard.sh -mcpu -O)" \
    # --enable-profiling \
    # --enable-libffi

/usr/bin/time make $(leopard.sh -j) VERBOSE=1

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

# Note: no 'make check' available.

make install VERBOSE=1

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
