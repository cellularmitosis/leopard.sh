#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install flex on OS X Tiger / PowerPC.

package=flex
version=2.6.4
upstream=https://github.com/westes/$package/archive/refs/tags/v$version.tar.gz
description="The Fast Lexical Analyzer"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: the tests fail to build with the system bison, so we install bison-3.8.2.
#   gcc -DHAVE_CONFIG_H -I. -I../src  -I../src -I../src   -mcpu=970 -O2 -c -o bison_nr_parser.o bison_nr_parser.c
#   bison_nr_parser.y:61: error: conflicting types for 'YYSTYPE'
#   bison_nr_parser.h:4: error: previous declaration of 'YYSTYPE' was here
#   /usr/share/bison.simple: In function 'testparse':
#   /usr/share/bison.simple:432: warning: passing argument 1 of 'testlex' from incompatible pointer type
#   make[2]: *** [bison_nr_parser.o] Error 1
if ! test -e /opt/bison-3.8.2 ; then
    tiger.sh bison-3.8.2
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

# if test -z "$ppc64" -a "$(tiger.sh --cpu)" = "g5" ; then
#     # Guile fails during a 32-bit build on a G5 machine,
#     # so we instead install the g4e binpkg in that case.
#     if tiger.sh --install-binpkg $pkgspec tiger.g4e ; then
#         exit 0
#     fi
# else
#     if tiger.sh --install-binpkg $pkgspec ; then
#         exit 0
#     fi
# fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(tiger.sh -mcpu -O)
CXXFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    YACC=/opt/bison-3.8.2/bin/bison \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS"

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

# Note: The tests fail to build for ppc64 when using g++-4.2, which is why we stick with the stock g++:
#   ../src/flex -o ccl.c ccl.l
#   gcc-4.2 -DHAVE_CONFIG_H -I. -I../src  -I../src -I../src   -m64 -mcpu=970 -O2 -c -o ccl.o ccl.c
#   /bin/sh ../libtool  --tag=CC   --mode=link gcc-4.2  -m64 -mcpu=970 -O2  -m64  -o ccl ccl.o  -lm 
#   libtool: link: gcc-4.2 -m64 -mcpu=970 -O2 -m64 -o ccl ccl.o  -lm
#   ../src/flex -+ -o cxx_basic.cc cxx_basic.ll
#   g++-4.2 -DHAVE_CONFIG_H -I. -I../src  -I../src -I../src   -m64 -mcpu=970 -O2 -c -o cxx_basic.o cxx_basic.cc
#   In file included from cxx_basic.cc:117:
#   /usr/include/c++/4.0.0/iostream:43:28: error: bits/c++config.h: No such file or directory
#   In file included from /usr/include/c++/4.0.0/ios:43,
#                    from /usr/include/c++/4.0.0/ostream:44,
#                    from /usr/include/c++/4.0.0/iostream:44,
#                    from cxx_basic.cc:117:
#   /usr/include/c++/4.0.0/iosfwd:45:29: error: bits/c++locale.h: No such file or directory
#   /usr/include/c++/4.0.0/iosfwd:46:25: error: bits/c++io.h: No such file or directory
#   In file included from /usr/include/c++/4.0.0/bits/ios_base.h:45,
#                    from /usr/include/c++/4.0.0/ios:48,
#                    from /usr/include/c++/4.0.0/ostream:44,
#                    from /usr/include/c++/4.0.0/iostream:44,
#                    from cxx_basic.cc:117:
#   /usr/include/c++/4.0.0/bits/atomicity.h:38:30: error: bits/atomic_word.h: No such file or directory
#   In file included from /usr/include/c++/4.0.0/memory:54,
#                    from /usr/include/c++/4.0.0/string:47,
#                    from /usr/include/c++/4.0.0/bits/locale_classes.h:47,
#                    from /usr/include/c++/4.0.0/bits/ios_base.h:47,
#                    from /usr/include/c++/4.0.0/ios:48,
#                    from /usr/include/c++/4.0.0/ostream:44,
#                    from /usr/include/c++/4.0.0/iostream:44,
#                    from cxx_basic.cc:117:
#   /usr/include/c++/4.0.0/bits/allocator.h:52:31: error: bits/c++allocator.h: No such file or directory
#   In file included from /usr/include/c++/4.0.0/bits/ios_base.h:47,
#                    from /usr/include/c++/4.0.0/ios:48,
#                    from /usr/include/c++/4.0.0/ostream:44,
#                    from /usr/include/c++/4.0.0/iostream:44,
#                    from cxx_basic.cc:117:
#   /usr/include/c++/4.0.0/bits/locale_classes.h:49:23: error: bits/gthr.h: No such file or directory
#   In file included from /usr/include/c++/4.0.0/bits/basic_ios.h:44,
#                    from /usr/include/c++/4.0.0/ios:50,
#                    from /usr/include/c++/4.0.0/ostream:44,
#                    from /usr/include/c++/4.0.0/iostream:44,
#                    from cxx_basic.cc:117:
#   /usr/include/c++/4.0.0/bits/locale_facets.h:132:31: error: bits/ctype_base.h: No such file or directory
#   /usr/include/c++/4.0.0/bits/locale_facets.h:1508:33: error: bits/ctype_inline.h: No such file or directory
#   /usr/include/c++/4.0.0/bits/locale_facets.h:2967:33: error: bits/time_members.h: No such file or directory
#   /usr/include/c++/4.0.0/bits/locale_facets.h:4491:37: error: bits/messages_members.h: No such file or directory
#   In file included from /usr/include/c++/4.0.0/ios:45,
#                    from /usr/include/c++/4.0.0/ostream:44,
#                    from /usr/include/c++/4.0.0/iostream:44,
#                    from cxx_basic.cc:117:
# (many, many more lines of output)
