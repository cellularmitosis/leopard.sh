#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install texinfo on OS X Tiger / PowerPC.

package=texinfo
version=6.8
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    libiconv-1.16$ppc64 \
    gettext-0.20$ppc64
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

CFLAGS="$(tiger.sh -mcpu -O)"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --with-libiconv-prefix=/opt/libiconv-1.16$ppc63 \
    --with-libintl-prefix=/opt/gettext-0.20$ppc64 \
    CFLAGS="$CFLAGS" \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS"

# Our flags aren't getting propagated to tp/Texinfo/XS/Makefile, which fails with:
#   parsetexi/api.c:28:21: error: libintl.h: No such file or directory
sed -i '' -e 's| -g | |g' tp/Texinfo/XS/Makefile
sed -i '' -e "s|^PERL_CONF_optimize =.*|PERL_CONF_optimize = $(tiger.sh -mcpu -O)|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|^PERL_EXT_CFLAGS =|PERL_EXT_CFLAGS = $CFLAGS|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|^PERL_EXT_CPPFLAGS =|PERL_EXT_CPPFLAGS = $CPPFLAGS|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|^PERL_EXT_LDFLAGS =|PERL_EXT_LDFLAGS = $LDFLAGS|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|^CFLAGS =|CFLAGS = $CFLAGS|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|^CPPFLAGS =|CPPFLAGS = $CPPFLAGS|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|^LDFLAGS =|LDFLAGS = $LDFLAGS|" tp/Texinfo/XS/Makefile
sed -i '' -e "s|-arch i386| |g" tp/Texinfo/XS/Makefile

sed -i '' -e "s|^PERL_CONF_optimize =.*|PERL_CONF_optimize = $(tiger.sh -mcpu -O)|" tp/Texinfo/XS/gnulib/lib/Makefile
sed -i '' -e "s|-arch i386| |g" tp/Texinfo/XS/gnulib/lib/Makefile

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
    # Note: there is one test failure:
    # zgrep-signal: set-up failure: signal handling busted on this host
    # ERROR: zgrep-signal
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
