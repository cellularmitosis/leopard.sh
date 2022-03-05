#!/bin/bash
# based on templates/build-from-source.sh v5

# Install bash on OS X Tiger / PowerPC.

package=bash
version=5.1.16
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    libiconv-1.16$ppc64 \
    gettext-0.20$ppc64 \
    ncurses-6.3$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --os.cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time \
    ./configure -C --prefix=/opt/$pkgspec \
        --enable-threads=posix \
        --with-installed-readline \
        --with-libiconv-prefix=/opt/libiconv-1.16$ppc64 \
        --with-libintl-prefix=/opt/gettext-0.20$ppc64 \
        CFLAGS="$CFLAGS" \
        LDFLAGS="$LDFLAGS" \
    && make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

make install

# Note: for some reason, bash is linking against both /usr/lib/libncurses as well as my
# ncurses in /opt/ncurses-6.3/lib/libncurses:
#     $ otool -L /opt/bash-5.1.16/bin/bash | grep ncurses
#         /usr/lib/libncurses.5.4.dylib (compatibility version 5.4.0, current version 5.4.0)
#         /opt/ncurses-6.3/lib/libncurses.6.dylib (compatibility version 6.0.0, current version 6.0.0)
#     $ otool -l /opt/bash-5.1.16/bin/bash
#         Load command 9
#                   cmd LC_LOAD_DYLIB
#               cmdsize 56
#                  name /usr/lib/libncurses.5.4.dylib (offset 24)
#            time stamp 2 Wed Dec 31 18:00:02 1969
#               current version 5.4.0
#         compatibility version 5.4.0
#         Load command 12
#                   cmd LC_LOAD_DYLIB
#               cmdsize 64
#                  name /opt/ncurses-6.3/lib/libncurses.6.dylib (offset 24)
#            time stamp 2 Wed Dec 31 18:00:02 1969
#               current version 6.0.0
#         compatibility version 6.0.0
#         Load command 13
# Here is the exact linker command:
#     gcc -L./builtins -L./lib/readline -L./lib/readline -L./lib/glob -L./lib/tilde  -L./lib/sh  -L/opt/ncurses-6.3/lib -L/opt/gettext-0.21/lib -L/opt/libiconv-1.16/lib   -mcpu=970 -O2    -o bash shell.o eval.o y.tab.o general.o make_cmd.o print_cmd.o  dispose_cmd.o execute_cmd.o variables.o copy_cmd.o error.o expr.o flags.o jobs.o subst.o hashcmd.o hashlib.o mailcheck.o trap.o input.o unwind_prot.o pathexp.o sig.o test.o version.o alias.o array.o arrayfunc.o assoc.o braces.o bracecomp.o bashhist.o bashline.o  list.o stringlib.o locale.o findcmd.o redir.o pcomplete.o pcomplib.o syntax.o xmalloc.o  -lbuiltins -lglob -lsh ./lib/readline/libreadline.a ./lib/readline/libhistory.a -ltermcap -ltilde  -lintl -L/opt/xz-5.2.5/lib -L/opt/libunistring-1.0/lib -L/opt/libiconv-bootstrap-1.16/lib -liconv -lncurses -Wl,-framework -Wl,CoreFoundation -liconv  -ldl 
# So we fix it after the fact:
if test -z "$ppc64" ; then
    install_name_tool -change \
        /usr/lib/libncurses.5.4.dylib \
        /opt/ncurses-6.3/lib/libncurses.6.dylib \
        /opt/$pkgspec/bin/bash
fi

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi

# Note: fails to build on ppc64:
# gcc -L./builtins -L./lib/readline -L./lib/readline -L./lib/glob -L./lib/tilde  -L./lib/sh  -m64 -L./lib/termcap -L./lib/termcap  -m64 -mcpu=970 -O2    -o bash shell.o eval.o y.tab.o general.o make_cmd.o print_cmd.o  dispose_cmd.o execute_cmd.o variables.o copy_cmd.o error.o expr.o flags.o jobs.o subst.o hashcmd.o hashlib.o mailcheck.o trap.o input.o unwind_prot.o pathexp.o sig.o test.o version.o alias.o array.o arrayfunc.o assoc.o braces.o bracecomp.o bashhist.o bashline.o  list.o stringlib.o locale.o findcmd.o redir.o pcomplete.o pcomplib.o syntax.o xmalloc.o  -lbuiltins -lglob -lsh ./lib/readline/libreadline.a ./lib/readline/libhistory.a ./lib/termcap/libtermcap.a -ltilde  -L/opt/gettext-0.20.ppc64/lib -lintl -L/opt/libiconv-bootstrap-1.16.ppc64/lib -liconv  -L/opt/libiconv-1.16.ppc64/lib -liconv  -ldl 
# Undefined symbols:
#   _BC, referenced from:
#       _BC$non_lazy_ptr in libreadline.a(terminal.o)
#       __data@0 in libtermcap.a(tparam.o)
#   _UP, referenced from:
#       _UP$non_lazy_ptr in libreadline.a(terminal.o)
#       __data@0 in libtermcap.a(tparam.o)
# ld64-62.1 failed: symbol(s) not found
# collect2: ld returned 1 exit status
# make: *** [bash] Error 1
