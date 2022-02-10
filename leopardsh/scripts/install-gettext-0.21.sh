#!/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install gettext on OS X Leopard / PowerPC.

# Note: gettext provides libintl.

package=gettext
version=0.21

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: there is a dependency cycle between gettext and libiconv.
# See the note in install-libiconv-bootstrap-1.16.sh.
for dep in \
    libiconv-bootstrap-1.16$ppc64 \
    libunistring-1.0$ppc64 \
    xz-5.2.5$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done
# LIBS="-lbar -lqux"

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --os.cpu))\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = e71133e1bad4f2ce83121078fd33edde

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache > config.cache

    CFLAGS=$(leopard.sh -mcpu -O)
    CXXFLAGS=$(leopard.sh -mcpu -O)
    if test -n "$ppc64" ; then
        CFLAGS="-m64 $CFLAGS"
        CXXFLAGS="-m64 $CXXFLAGS"
        # LDFLAGS="-m64 $LDFLAGS"
    fi

    ./configure -C --prefix=/opt/$pkgspec \
        --with-libiconv-prefix=/opt/libiconv-bootstrap-1.16$ppc64 \
        --with-libcurses-prefix=/opt/ncurses-6.3$ppc64 \
        --with-libunistring-prefix=/opt/libunistring-1.0$ppc64 \
        CPPFLAGS="$CPPFLAGS" \
        LDFLAGS="$LDFLAGS" \
        CFLAGS="$CFLAGS" \
        CXXFLAGS="$CXXFLAGS"

    make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
        # Two failing tests on ppc:
        # FAIL: msgunfmt-java-1
        # FAIL: lang-java

        # 21 failing tests on ppc64:
        # FAIL: msgattrib-properties-1
        # FAIL: msgcat-properties-1
        # FAIL: msgcat-properties-2
        # FAIL: msgcmp-3
        # FAIL: msgcomm-24
        # FAIL: msgconv-4
        # FAIL: msgen-2
        # FAIL: msgexec-3
        # FAIL: msgfilter-3
        # FAIL: msgfmt-properties-1
        # FAIL: msggrep-6
        # FAIL: msgmerge-properties-1
        # FAIL: msgmerge-properties-2
        # FAIL: msgunfmt-java-1
        # FAIL: msgunfmt-properties-1
        # FAIL: msguniq-4
        # FAIL: xgettext-properties-1
        # FAIL: xgettext-properties-2
        # FAIL: xgettext-properties-3
        # FAIL: xgettext-properties-4
        # FAIL: lang-java

        make check
    fi

    make install

    leopard.sh --linker-check $pkgspec
    leopard.sh --arch-check $pkgspec $ppc64

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi
