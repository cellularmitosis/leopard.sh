#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install FFTW on OS X Tiger / PowerPC.

package=fftw
version=3.3.10
upstream=https://www.fftw.org/fftw-$version.tar.gz
description="Fastest Fourier Transform in the West"

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

patch -p1 << 'EOF'
--- a/configure	2023-08-20 23:11:19.000000000 -0500
+++ b/configure	2023-08-20 23:11:56.000000000 -0500
@@ -15165,6 +15165,7 @@
 rm -f core conftest.err conftest.$ac_objext conftest.$ac_ext
       CFLAGS=$ax_save_FLAGS
 fi
+ax_cv_c_flags__Wa=no
 
 eval ax_check_compiler_flags=$ax_cv_c_flags__Wa
 { $as_echo "$as_me:${as_lineno-$LINENO}: result: $ax_check_compiler_flags" >&5
@@ -15203,6 +15204,7 @@
 rm -f core conftest.err conftest.$ac_objext conftest.$ac_ext
       CFLAGS=$ax_save_FLAGS
 fi
+ax_cv_c_flags__Wl=no
 
 eval ax_check_compiler_flags=$ax_cv_c_flags__Wl
 { $as_echo "$as_me:${as_lineno-$LINENO}: result: $ax_check_compiler_flags" >&5
EOF

CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure --prefix=/opt/$pkgspec \
    --enable-shared \
    --enable-threads \
    F77=gfortran-4.9 \
    CC=gcc-4.9 \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS"

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
