#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install perl on OS X Tiger / PowerPC.

# Note: this is a minimal build of perl which is only used to configure OpenSSL.

package=perl
version=5.36.0
upstream=https://www.cpan.org/src/5.0/$package-$version.tar.gz
description="Larry Wall's Practical Extraction and Report Language"

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

# gcc-4.2 needed for -Wno-error=implicit-function-declaration.
CC=gcc-4.2

CC="$CC" ./configure.gnu --prefix=/opt/$pkgspec

# LD_RUN_PATH="/usr/lib" env MACOSX_DEPLOYMENT_TARGET=10.3 gcc-4.2 -Wl,-rpath,"/usr/lib" -bundle -undefined dynamic_lookup -L/usr/local/lib  NDBM_File.o  -o ../../lib/auto/NDBM_File/NDBM_File.bundle -ldbm
# /usr/libexec/gcc/powerpc-apple-darwin8/4.2.1/ld: unknown flag: -rpath
# collect2: ld returned 1 exit status
# make[1]: *** [../../lib/auto/NDBM_File/NDBM_File.bundle] Error 1

sed -i '' -e 's/MACOSX_DEPLOYMENT_TARGET=10.3/MACOSX_DEPLOYMENT_TARGET=10.4/' config.sh
./Configure -der

# Note: the NDBM_File Makefile doesn't exist until after we run make the first time,
# so we don't have an opportunity to edit the Makefile until after the build fails.
# So we allow the build to fail once, then edit the Makefile, then run the build again.
/usr/bin/time make $(tiger.sh -j) OPTIMIZE='-O0' || true

# NDBM_File seems to be hard-coded to link using rpath, despite MACOSX_DEPLOYMENT_TARGET.
sed -i '' -e 's|-Wl,-rpath,"/usr/lib"||' ext/NDBM_File/Makefile

/usr/bin/time make $(tiger.sh -j) OPTIMIZE='-O0'

if test -n "$TIGERSH_RUN_TESTS" ; then
    make test
fi

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
