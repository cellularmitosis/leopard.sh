#!/bin/bash
# based on templates/build-from-source.sh v6

# Install libiconv on OS X Leopard / PowerPC.

# Note: there is a circular dependency between libiconv and gettext.  This
# package is a second copy of libiconv used to break the circular dependency.

# Quoting from https://www.gnu.org/software/libiconv/
# After installing GNU libiconv for the first time, it is recommended to
# recompile and reinstall GNU gettext, so that it can take advantage of libiconv.
# On systems other than GNU/Linux, the iconv program will be internationalized
# only if GNU gettext has been built and installed before GNU libiconv. This
# means that the first time GNU libiconv is installed, we have a circular
# dependency between the GNU libiconv and GNU gettext packages, which can be
# resolved by building and installing either:
# - first libiconv, then gettext, then libiconv again,
# or (on systems supporting shared libraries, excluding AIX)
# - first gettext, then libiconv, then gettext again.

package=libiconv-bootstrap
version=1.16
upstream=https://ftp.gnu.org/gnu/$package/libiconv-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

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

leopard.sh --unpack-dist libiconv-$version
cd /tmp/libiconv-$version

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    CFLAGS="$CFLAGS"

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
