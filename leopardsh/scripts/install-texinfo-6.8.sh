#!/bin/bash
# based on templates/build-from-source.sh v6

# Install texinfo on OS X Leopard / PowerPC.

package=texinfo
version=6.8
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    libiconv-1.16$ppc64 \
    gettext-0.21$ppc64
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
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --with-libiconv-prefix=/opt/libiconv-1.16$ppc63 \
    --with-libintl-prefix=/opt/gettext-0.21$ppc64 \
    CFLAGS="$CFLAGS" \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS"

# Our flags aren't getting propagated to tp/Texinfo/XS/Makefile, which fails with:
#   parsetexi/api.c:28:21: error: libintl.h: No such file or directory
sed -i '' -e 's| -g | |g' tp/Texinfo/XS/Makefile
sed -i '' -e "s|^PERL_CONF_optimize =.*|PERL_CONF_optimize = $(leopard.sh -mcpu -O)|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|^PERL_EXT_CFLAGS =|PERL_EXT_CFLAGS = $CFLAGS|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|^PERL_EXT_CPPFLAGS =|PERL_EXT_CPPFLAGS = $CPPFLAGS|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|^PERL_EXT_LDFLAGS =|PERL_EXT_LDFLAGS = $LDFLAGS|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|^CFLAGS =|CFLAGS = $CFLAGS|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|^CPPFLAGS =|CPPFLAGS = $CPPFLAGS|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|^LDFLAGS =|LDFLAGS = $LDFLAGS|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|-arch i386| |g" tp/Texinfo/XS/Makefile

sed -i '' -e "s|^PERL_CONF_optimize =.*|PERL_CONF_optimize = $(leopard.sh -mcpu -O)|" tp/Texinfo/XS/gnulib/lib/Makefile
sed -i '' -e "s|-arch i386| |g" tp/Texinfo/XS/gnulib/lib/Makefile

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
