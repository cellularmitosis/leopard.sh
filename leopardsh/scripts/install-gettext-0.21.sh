#!/bin/bash
# based on templates/build-from-source.sh v6

# Install gettext on OS X Leopard / PowerPC.

# Note: gettext provides libintl.

package=gettext
version=0.21
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: there is a dependency cycle between gettext and libiconv.
# See the note in install-libiconv-bootstrap-1.16.sh.

for dep in \
    libiconv-bootstrap-1.16$ppc64 \
    libunistring-1.0$ppc64 \
    ncurses-6.3$ppc64 \
    xz-5.2.5$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
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
CXXFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-libiconv-prefix=/opt/libiconv-bootstrap-1.16$ppc64 \
    --with-libcurses-prefix=/opt/ncurses-6.3$ppc64 \
    --with-libunistring-prefix=/opt/libunistring-1.0$ppc64 \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LIBS="-lncurses"

/usr/bin/time make $(leopard.sh -j) V=1

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

# gettext doesn't provide any .pc files.
mkdir -p /opt/$pkgspec/lib/pkgconfig
cat > /opt/$pkgspec/lib/pkgconfig/intl.pc << EOF
prefix=/opt/$pkgspec
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: intl
Description: GNU internationalization (i18n) and localization (l10n) library
Version: $version
Libs: -L\${libdir} -lintl
Cflags: -I\${includedir}
EOF

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
