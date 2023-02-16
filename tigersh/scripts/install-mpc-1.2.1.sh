#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install mpc on OS X Tiger / PowerPC.

package=mpc
version=1.2.1
upstream=https://gcc.gnu.org/pub/gcc/infrastructure/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    gmp-6.2.1$ppc64 \
    mpfr-4.1.0$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done

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

if ! test -d /opt/gcc-4.9.4 ; then
    if test -L /opt/gcc-4.9.4 ; then
        rm /opt/gcc-4.9.4
    fi
    tiger.sh gcc-4.9.4
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CC=gcc-4.9

# Note: gcc-4.9 does not support '-no-cpp-precomp'.
CFLAGS="$(tiger.sh -mcpu -O) -pedantic"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

cpu=$(tiger.sh --cpu)
if test "$cpu" = "g4e" \
|| test "$cpu" = "g4" \
|| test "$cpu" = "g5" -a -z "$ppc64"
then
    # Note: see the comments in install-gmp-4.3.2.sh re: force_cpusubtype_ALL.
    CFLAGS="$CFLAGS -force_cpusubtype_ALL"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-gmp=/opt/gmp-6.2.1$ppc64 \
    --with-mpfr=/opt/mpfr-4.1.0$ppc64 \
    CFLAGS="$CFLAGS" \
    CC="$CC"


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
