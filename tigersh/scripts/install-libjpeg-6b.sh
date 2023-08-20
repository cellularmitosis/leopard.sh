#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install libjpeg on OS X Tiger / PowerPC.

package=libjpeg
version=6b
upstream=https://newcontinuum.dl.sourceforge.net/project/libjpeg/libjpeg/6b/jpegsrc.v6b.tar.gz
description="JPEG C library"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

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

dep=libtool-2.4.6
if ! test -e /opt/$dep ; then
    tiger.sh $dep
fi

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

sed -i '' -e 's/--mode=link $(CC) -o/--mode=link $(CC) $(LDFLAGS) -o/' makefile.cfg

/usr/bin/time ./configure --prefix=/opt/$pkgspec \
    --enable-static \
    --enable-shared \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS"

# libjpeg's makefile seems to require ./libtool but doesn't provide it?
ln -s /opt/libtool-2.4.6/bin/libtool .

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

# libjpeg's installer doesn't make any directories?!?
for d in bin include lib man/man1 ; do
    mkdir -p /opt/$pkgspec/$d
done

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
