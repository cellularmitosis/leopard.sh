#!/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install pth on OS X Tiger / PowerPC.

package=pth
version=2.0.7

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

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

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 9cb4a25331a4c4db866a31cbe507c793

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    CFLAGS=$(tiger.sh -mcpu -O)
    # Note: using the CFLAGS approach isn't sufficient, the link step still ends
    # up not using the -mcpu flag, resulting in an arch of 'ppc':
    # ./libtool --mode=link --quiet gcc -o libpth.la pth_debug.lo pth_ring.lo pth_pqueue.lo pth_time.lo pth_errno.lo pth_mctx.lo pth_uctx.lo pth_tcb.lo pth_sched.lo pth_attr.lo pth_lib.lo pth_event.lo pth_data.lo pth_clean.lo pth_cancel.lo pth_msg.lo pth_sync.lo pth_fork.lo pth_util.lo pth_high.lo pth_syscall.lo pth_ext.lo pth_compat.lo pth_string.lo \
    # -rpath /opt/pth-2.0.7/lib -version-info `./shtool version -lc -dlibtool pth_vers.c`
    CC="gcc $(tiger.sh -mcpu)"
    if test -n "$ppc64" ; then
        CFLAGS="-m64 $CFLAGS"

        # LDFLAGS="-m64 $LDFLAGS"
        # Note: the LDFLAGS approach isn't working:
        #   ./libtool --mode=link --quiet gcc -m64 -o test_std test_std.o test_common.o libpth.la -ldl 
        #   ld warning: in ./.libs/libpth.dylib, file is not of required architecture
        #   Undefined symbols:
        #     "_pth_attr_set", referenced from:
        #         _main in test_std.o
        #         _main in test_std.o
        # Instead, we set CC:
        CC="$CC -m64"
    fi

    ./configure -C --prefix=/opt/$pkgspec \
        CFLAGS="$CFLAGS" \
        LDFLAGS="$LDFLAGS" \
        CC="$CC"

    # make $(tiger.sh -j) V=1
    # Note: using 'make -j2' causes the build to fail:
    # + make -j2 V=1
    # ./shtool scpp -o pth_p.h -t pth_p.h.in -Dcpp -Cintern -M '==#==' pth_compat.c pth_debug.c pth_syscall.c pth_errno.c pth_ring.c pth_mctx.c pth_uctx.c pth_clean.c pth_time.c pth_tcb.c pth_util.c pth_pqueue.c pth_event.c pth_sched.c pth_data.c pth_msg.c pth_cancel.c pth_sync.c pth_attr.c pth_lib.c pth_fork.c pth_high.c pth_ext.c pth_string.c pthread.c
    # ./libtool --mode=compile --quiet gcc -mcpu=7400 -c -I. -mcpu=7400 -Os -pipe pth_uctx.c
    # pth_uctx.c:31:19: error: pth_p.h: No such file or directory
    make V=1


    if test -n "$TIGERSH_RUN_TESTS" ; then
        # Note: surprisingly, the tests pass on tiger but fail on leopard.
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
