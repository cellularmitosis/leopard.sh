#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install freetype on OS X Tiger / PowerPC.

package=freetype
version=2.13.0
upstream=https://download.savannah.gnu.org/releases/$package/$package-$version.tar.gz
description="High-quality and portable font engine"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# 👇 EDIT HERE:
# dep=bar-1.0$ppc64
# if ! test -e /opt/$dep ; then
#     tiger.sh $dep
#     PATH="/opt/$dep/bin:$PATH"
# fi

# 👇 EDIT HERE:
# for dep in \
#     bar-2.1$ppc64 \
#     qux-3.4$ppc64
# do
#     if ! test -e /opt/$dep ; then
#         tiger.sh $dep
#     fi
#     CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
#     LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
#     PATH="/opt/$dep/bin:$PATH"
#     PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
# done
# LIBS="-lbar -lqux"
# PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"

# 👇 EDIT HERE:
# if ! perl -e "use Text::Unidecode" >/dev/null 2>&1 ; then
#     echo no | cpan
#     cpan Text::Unidecode
# fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

# 👇 EDIT HERE:
# if ! type -a pkg-config >/dev/null 2>&1 ; then
#     tiger.sh pkg-config-0.29.2
# fi
# export PATH="/opt/pkg-config-0.29.2/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# 👇 EDIT HERE:
CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(tiger.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# TODO: flesh this out:
# Library configuration:
#   external zlib: yes (autoconf test)
#   bzip2:         yes (autoconf test)
#   libpng:        no
#   harfbuzz:      no
#   brotli:        no
#   pthread:       no

# 👇 EDIT HERE:
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    # --with-bar=/opt/bar-1.0$ppc64 \
    # --with-bar-prefix=/opt/bar-1.0$ppc64 \
    # LDFLAGS="$LDFLAGS" \
    # CPPFLAGS="$CPPFLAGS" \
    # LIBS="$LIBS" \
    # CC="$CC" \
    # CXX="$CXX" \
    # PKG_CONFIG=/opt/pkg-config-0.29.2/bin/pkg-config \
    # PKG_CONFIG_PATH="/opt/libfoo-1.0$ppc64/lib/pkgconfig:/opt/libbar-1.0$ppc64/lib/pkgconfig" \

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
