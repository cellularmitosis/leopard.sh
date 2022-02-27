#!/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install gmp on OS X Tiger / PowerPC.

package=gmp
version=4.3.2

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --os.cpu))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
        tiger.sh gcc-4.2
    fi

    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 2a431d487dfd76d0f618d241b1e551cc

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    # Note: /usr/bin/gcc (4.0.1) fails with:
    #   ld: duplicate symbol ___gmpz_abs in .libs/compat.o and .libs/assert.o
    # So we use gcc-4.2 instead.
    # Thanks to https://gmplib.org/list-archives/gmp-bugs/2010-January/001837.html
    CC=gcc-4.2

    # Note: we do _not_ use g++-4.2, as that appears to be missing certain headers
    # like bits/c++config.h:
    #     $ find /usr | grep c++config
    #     /usr/include/c++/4.0.0/i686-apple-darwin8/bits/c++config.h
    #     /usr/include/c++/4.0.0/powerpc-apple-darwin8/bits/c++config.h
    #     /usr/include/c++/4.0.0/powerpc64-apple-darwin8/bits/c++config.h
    #     /usr/include/c++/4.0.0/x86_64-apple-darwin8/bits/c++config.h
    #     /usr/include/gcc/darwin/3.3/c++/i386-darwin/bits/c++config.h
    #     /usr/include/gcc/darwin/3.3/c++/ppc-darwin/bits/c++config.h
    # which causes configure to fail:
    #     checking C++ compiler g++-4.2 -mcpu=970 -O2 -m64  -pedantic -no-cpp-precomp... no, std iostream
    #     configure: error: C++ compiler not available, see config.log for details
    #     Test compile: std iostream
    #     configure:9383: g++-4.2 -mcpu=970 -O2 -m64  -pedantic -no-cpp-precomp conftest.cc >&5
    #     In file included from conftest.cc:3:
    #     /usr/include/c++/4.0.0/iostream:43:28: error: bits/c++config.h: No such file or directory
    CXX=g++

    # Note: gmp is extra finicky with regard to flags.  Hacks ahead.
    # It was a pain to figure all of this out.

    CC="$CC $(tiger.sh -mcpu -O)"
    CXX="$CXX $(tiger.sh -mcpu -O)"
    LDFLAGS="$LDFLAGS $(tiger.sh -mcpu -O)"

    if test -n "$ppc64" ; then
        CC="$CC -m64"
        CXX="$CXX -m64"
        LDFLAGS="$LDFLAGS -m64"
    fi

    cpu=$(tiger.sh --cpu)
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

    CFLAGS="-pedantic -no-cpp-precomp"
    CXXFLAGS="-pedantic -no-cpp-precomp"

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

    ./configure -C --prefix=/opt/$pkgspec \
        --enable-cxx \
        $abi \
        CFLAGS="$CFLAGS" \
        CXXFLAGS="$CXXFLAGS" \
        CC="$CC" \
        CXX="$CXX" \
        LDFLAGS="$LDFLAGS" \
        MPN_PATH="$MPN_PATH"

    make $(tiger.sh -j)

    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi

    make install

    tiger.sh --linker-check $pkgspec
    tiger.sh --arch-check $pkgspec $ppc64

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi
