#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install bash on OS X Tiger / PowerPC.

package=bash
version=5.1.16

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/libiconv-1.16$ppc64 ; then
    tiger.sh libiconv-1.16$ppc64
fi

if ! test -e /opt/gettext-0.20$ppc64 ; then
    tiger.sh gettext-0.20$ppc64
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = c17b20a09fc38d67fb303aeb6c130b4e

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(tiger.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(tiger.sh -m32 -mcpu -O)
    fi
    export CFLAGS

    ./configure -C --prefix=/opt/$pkgspec \
        --enable-threads=posix \
        --with-installed-readline \
        --with-libiconv-prefix=/opt/libiconv-1.16$ppc64 \
        --with-libintl-prefix=/opt/gettext-0.20$ppc64

    make $(tiger.sh -j) V=1

    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi

    make install

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
