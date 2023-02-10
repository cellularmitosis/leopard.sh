#!/bin/bash
# based on templates/build-from-source.sh v6

# Install guile on OS X Leopard / PowerPC.

package=guile
version=1.8.8
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    gmp-4.3.2$ppc64 \
    libiconv-1.16$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done
LIBS="-lgmp -liconv"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if test -z "$ppc64" -a "$(leopard.sh --cpu)" = "g5" ; then
    # Guile fails during a 32-bit build on a G5 machine,
    # so we instead install the g4e binpkg in that case.
    if leopard.sh --install-binpkg $pkgspec leopard.g4e ; then
        exit 0
    fi
else
    if leopard.sh --install-binpkg $pkgspec ; then
        exit 0
    fi
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
elif test "$(leopard.sh --cpu)" = "g5" ; then
    # 32-bit G5 builds fail with:
    #   libtool: compile:  gcc -DHAVE_CONFIG_H -I.. -I.. -I.. -I/opt/libiconv-1.16/include -I/opt/gmp-4.3.2/include -I/opt/libiconv-1.16/include -I/opt/gmp-4.3.2/include -D_THREAD_SAFE -mcpu=970 -O2 -Wall -Wmissing-prototypes -Werror -MT libguile_la-gc-mark.lo -MD -MP -MF .deps/libguile_la-gc-mark.Tpo -c gc-mark.c  -fno-common -DPIC -o .libs/libguile_la-gc-mark.o
    #   cc1: warnings being treated as errors
    #   gc-mark.c: In function 'scm_mark_all':
    #   gc-mark.c:96: warning: cast to pointer from integer of different size
    #   make[3]: *** [libguile_la-gc-mark.lo] Error 1
    patch -p1 << 'EOF'
diff '--color=auto' -urN guile-1.8.8/libguile/gc-mark.c guile-1.8.8.patched/libguile/gc-mark.c
--- guile-1.8.8/libguile/gc-mark.c	2010-12-13 11:24:40.000000000 -0600
+++ guile-1.8.8.patched/libguile/gc-mark.c	2023-02-10 02:45:27.643266044 -0600
@@ -93,7 +93,7 @@
 	SCM l = SCM_HASHTABLE_BUCKET (scm_gc_registered_roots, i);
 	for (; !scm_is_null (l); l = SCM_CDR (l))
 	  {
-	    SCM *p = (SCM *) (scm_to_ulong (SCM_CAAR (l)));
+	    SCM *p = (SCM *) (scm_to_uint32 (SCM_CAAR (l)));
 	    scm_gc_mark (*p);
 	  }
       }
EOF

    # 32-bit G5 builds fail with:
    #   libtool: compile:  gcc -DHAVE_CONFIG_H -I.. -I.. -I.. -I/opt/readline-8.2/include -I/opt/libiconv-1.16/include -I/opt/gmp-4.3.2/include -I/opt/readline-8.2/include -I/opt/libiconv-1.16/include -I/opt/gmp-4.3.2/include -D_THREAD_SAFE -mcpu=970 -O2 -Wall -Wmissing-prototypes -Werror -MT libguile_la-numbers.lo -MD -MP -MF .deps/libguile_la-numbers.Tpo -c numbers.c  -fno-common -DPIC -o .libs/libguile_la-numbers.o
    #   cc1: warnings being treated as errors
    #   In file included from numbers.c:5907:
    #   ../libguile/conv-integer.i.c: In function 'scm_to_int64':
    #   ../libguile/conv-integer.i.c:35: warning: comparison is always true due to limited range of data type
    #   ../libguile/conv-integer.i.c:35: warning: comparison is always true due to limited range of data type
    #   ../libguile/conv-integer.i.c:56: warning: comparison is always true due to limited range of data type
    #   ../libguile/conv-integer.i.c:56: warning: comparison is always true due to limited range of data type
    #   In file included from numbers.c:5915:
    #   ../libguile/conv-uinteger.i.c: In function 'scm_to_uint64':
    #   ../libguile/conv-uinteger.i.c:56: warning: comparison is always true due to limited range of data type
    #   make[3]: *** [libguile_la-numbers.lo] Error 1
    exit 1

    # Note: forcing -m32 didn't help.
fi

# Note: there is no --with-gmp option.
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-libiconv-prefix=/opt/libiconv-1.16$ppc64 \
    --with-threads \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    LIBS="$LIBS" \
    CFLAGS="$CFLAGS"

/usr/bin/time make $(leopard.sh -j) V=1

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
