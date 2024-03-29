#!/bin/bash
# based on templates/build-from-source.sh v6

# Install gmp on OS X Leopard / PowerPC.

package=gmp
version=6.2.1
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.bz2

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gcc-4.9.4 ; then
    leopard.sh gcc-libs-4.9.4
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

if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CC=gcc-4.9
CXX=g++-4.9

# Note: gmp is extra finicky with regard to flags.  Hacks ahead.
# It was a pain to figure all of this out.

CC="$CC $(leopard.sh -mcpu -O)"
CXX="$CXX $(leopard.sh -mcpu -O)"
LDFLAGS="$(leopard.sh -mcpu -O)"

if test -n "$ppc64" ; then
    CC="$CC -m64"
    CXX="$CXX -m64"
    LDFLAGS="$LDFLAGS -m64"
fi

cpu=$(leopard.sh --cpu)
if test "$cpu" = "g4e" \
|| test "$cpu" = "g4" \
|| test "$cpu" = "g5" -a -z "$ppc64"
then
    # Note: it appears force_cpusubtype_ALL is required when using altivec in asm files:
    # tmp-mod_34lsub1.s:166:vxor vector instruction is optional for the PowerPC (not allowed without -force_cpusubtype_ALL option)
    CC="$CC -force_cpusubtype_ALL"
    CXX="$CXX -force_cpusubtype_ALL"
    # Note that this will cause the arch to be reported correctly on G5/64:
    #     Non-fat file: lib/libgmp.3.5.2.dylib is architecture: ppc64
    # and also on G3:
    #     Non-fat file: lib/libgmp.3.5.2.dylib is architecture: ppc750
    # but will appear as "ppc" for G5/32, G4, and G4e:
    #     Non-fat file: lib/libgmp.3.5.2.dylib is architecture: ppc
fi

# Note: gcc-4.9 does not support '-no-cpp-precomp'.
CFLAGS="-pedantic"
CXXFLAGS="-pedantic"

# Note: these MPN_PATH values may appear confusing (e.g. why use 750 on a G4?),
# but this is just confusing naming choices on the part of mpn.
# From mpn/powerpc32/README:
#   powerpc           generic, 604, 604e, 744x, 745x
#   powerpc/750       740, 750, 7400, 7410
# So "powerpc/750" also applies to G4.
# Additionally, mpn doesn't have a specific MPN_PATH for the G5, so for
# G5/32, we treat it like a G4.

if test "$cpu" = "g5" ; then
    if test -n "$ppc64" ; then
        MPN_PATH="powerpc64/mode64 powerpc64/vmx powerpc64 generic"
    else
        # MPN_PATH="powerpc64/mode32 powerpc64/vmx powerpc32/750 powerpc32 generic"
        # Note: for G5/32, ideally we'd try powerpc64/mode32, but this causes
        # gmp.h to make 64-bit defines, which breaks mpfr:
        #   configure: error: GMP_NUMB_BITS and sizeof(mp_limb_t) are not consistent,
        # so we just make it the same as the G4 build.
        MPN_PATH="powerpc32/vmx powerpc32/750 powerpc32 generic"
    fi
elif test "$cpu" = "g4e" -o "$cpu" = "g4" ; then
    MPN_PATH="powerpc32/vmx powerpc32/750 powerpc32 generic"
elif test "$cpu" = "g3" ; then
    MPN_PATH="powerpc32/750 powerpc32 generic"
fi

if test -n "$ppc64" ; then
    abi="ABI=mode64"
else
    abi="ABI=32"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --enable-cxx \
    $abi \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    CC="$CC" \
    CXX="$CXX" \
    LDFLAGS="$LDFLAGS" \
    MPN_PATH="$MPN_PATH"

/usr/bin/time make $(leopard.sh -j)

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
