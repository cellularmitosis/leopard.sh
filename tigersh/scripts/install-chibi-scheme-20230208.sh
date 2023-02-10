#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install chibi-scheme on OS X Tiger / PowerPC.

package=chibi-scheme
version=20230208
upstream=https://github.com/ashinn/$package/archive/refs/heads/master.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# BSD libutil didn't ship with OS X until Leopard.
for dep in \
    libutil-11$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done
LIBS="-lutil"

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

# Prior to Leopard, unsetenv returned void rather than int.
#   lib/chibi/ast.c: In function 'sexp_unsetenv':
#   lib/chibi/ast.c:616: error: void value not ignored as it ought to be
patch -p1 << 'EOF'
diff '--color=auto' -urN chibi-scheme-20230208/lib/chibi/ast.c chibi-scheme-20230208.patched/lib/chibi/ast.c
--- chibi-scheme-20230208/lib/chibi/ast.c	2023-02-08 06:38:00.000000000 -0600
+++ chibi-scheme-20230208.patched/lib/chibi/ast.c	2023-02-09 23:03:12.593619651 -0600
@@ -9,6 +9,10 @@
 #include <errno.h>
 #endif
 
+#ifdef __APPLE__
+#include <AvailabilityMacros.h>
+#endif
+
 #ifdef _WIN32
 #if defined(__MINGW32__) || defined(__MINGW64__)
 /* Workaround MinGW header implementation */
@@ -611,10 +615,19 @@
   return sexp_make_boolean(setenv(sexp_string_data(name), sexp_string_data(value), 1));
 }
 
+#if defined(__APPLE__) && !defined(MAC_OS_X_VERSION_10_5)
+sexp sexp_unsetenv (sexp ctx, sexp self, sexp_sint_t n, sexp name) {
+  sexp_assert_type(ctx, sexp_stringp, SEXP_STRING, name);
+  /* Prior to Leopard, unsetenv returned void. */
+  unsetenv(sexp_string_data(name));
+  return SEXP_TRUE;
+}
+#else
 sexp sexp_unsetenv (sexp ctx, sexp self, sexp_sint_t n, sexp name) {
   sexp_assert_type(ctx, sexp_stringp, SEXP_STRING, name);
   return sexp_make_boolean(unsetenv(sexp_string_data(name)));
 }
+#endif
 
 sexp sexp_abort (sexp ctx, sexp self, sexp_sint_t n, sexp value) {
   sexp res = sexp_make_trampoline(ctx, SEXP_FALSE, value);
EOF

# RTLD_SELF wasn't introduced until Leopard.
#   gc_heap.c: In function 'load_image_fn':
#   gc_heap.c:526: error: 'RTLD_SELF' undeclared (first use in this function)
patch -p1 << 'EOF'
diff '--color=auto' -urN chibi-scheme-20230208/gc_heap.c chibi-scheme-20230208.patched/gc_heap.c
--- chibi-scheme-20230208/gc_heap.c	2023-02-08 06:38:00.000000000 -0600
+++ chibi-scheme-20230208.patched/gc_heap.c	2023-02-09 23:29:29.645694404 -0600
@@ -4,6 +4,10 @@
 
 #include "chibi/gc_heap.h"
 
+#ifdef __APPLE__
+#include <AvailabilityMacros.h>
+#endif
+
 #if SEXP_USE_IMAGE_LOADING
 
 #define ERR_STR_SIZE 256
@@ -426,7 +430,8 @@
 
 #if SEXP_USE_DL
 
-#ifdef __APPLE__
+#if defined(__APPLE__) && defined(MAC_OS_X_VERSION_10_5)
+/* Starting with Leopard, Apple provides RTLD_SELF. */
 #define SEXP_RTLD_DEFAULT RTLD_SELF
 #else
 #define SEXP_RTLD_DEFAULT RTLD_DEFAULT
EOF

# SRFI 144 fails because it is actually C99, not C89:
#   cc  -dynamiclib  -Iinclude  -DSEXP_USE_INTTYPES -Wall -g -g3 -O3   -o lib/srfi/144/math.dylib lib/srfi/144/math.c -L.   -lchibi-scheme
#   lib/srfi/144/math.c: In function 'sexp_compute_least_double':
#   lib/srfi/144/math.c:8: error: 'for' loop initial declaration used outside C99 mode
#   make: *** [lib/srfi/144/math.dylib] Error 1
#
# The easy solution is to just use C99 for everything:
CC="gcc -std=c99"

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"

# Note: ppc64 build fails with:
#   gcc -std=c99  -dynamiclib -install_name /opt/chibi-scheme-20230208.ppc64/lib/libchibi-scheme.0.10.0.dylib -o libchibi-scheme.0.10.0.dylib gc.o sexp.o bignum.o gc_heap.o opcodes.o vm.o eval.o simplify.o -m64 -L/opt/libutil-11.ppc64/lib  -lutil   -ldl -lm
#   Undefined symbols:
#     ___multi3, referenced from:
#         _sexp_bignum_fxmul in bignum.o
#         _sexp_bignum_fxrem in bignum.o
#         _sexp_mul in bignum.o
#         _sexp_apply in vm.o
#     ___udivti3, referenced from:
#         _sexp_bignum_fxdiv in bignum.o
#         _sexp_bignum_fxrem in bignum.o
#         _sexp_bignum_quot_rem in bignum.o
#         _sexp_bignum_quot_rem in bignum.o
#   ld64-62.1 failed: symbol(s) not found
#   /usr/libexec/gcc/powerpc-apple-darwin8/4.0.1/libtool: internal link edit command failed
#   make: *** [libchibi-scheme.0.10.0.dylib] Error 1
    exit 1
fi

# We'll pass in our own optimization flags.
perl -pi -e "s/-g -g3 -O3//g" Makefile.detect

/usr/bin/time make $(tiger.sh -j) \
    PREFIX=/opt/$pkgspec \
    CC="$CC" \
    CPPFLAGS="$CPPFLAGS" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS $LIBS"

# Note: no 'make check' available.

make PREFIX=/opt/chibi-scheme-20230208 install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
