#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install gettext on OS X Tiger / PowerPC.

# Note: gettext provides libintl.

package=gettext
version=0.20
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

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
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
done

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

CFLAGS=$(tiger.sh -mcpu -O)
CXXFLAGS=$(tiger.sh -mcpu -O)
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

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
    # Four failing tests:
    # FAIL: msgcat-17
    # FAIL: msgfilter-sr-latin-1
    # FAIL: msgmerge-11
    # FAIL: xgettext-python-1
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

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
