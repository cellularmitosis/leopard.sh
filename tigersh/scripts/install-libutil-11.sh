#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install libutil on OS X Tiger / PowerPC.

package=libutil
version=11
upstream=https://github.com/apple-oss-distributions/$package/archive/refs/tags/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

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

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64"
fi

perl -pi -e "s|-Os -g3|$CFLAGS|g" Makefile
perl -pi -e "s|-install_name /usr/lib/libutil.dylib|$LDFLAGS -install_name /opt/$pkgspec/lib/libutil.dylib|g" Makefile
/usr/bin/time make $(tiger.sh -j)

# Note: no 'make check' available.

# Using Apple's Makefile to perform installation causes unwanted paths,
# e.g. /opt/libutil-11/usr/local/...
# So we just install manually.
mkdir -p /opt/$pkgspec/include
cp libutil.h mntopts.h /opt/$pkgspec/include
mkdir -p /opt/$pkgspec/lib
cp libutil1.0.dylib /opt/$pkgspec/lib
ln -fs libutil1.0.dylib /opt/$pkgspec/lib/libutil.dylib
mkdir -p /opt/$pkgspec/share/man/man3
cp *.3 /opt/$pkgspec/share/man/man3/

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
