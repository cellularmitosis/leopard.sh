#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install tar on OS X Tiger / PowerPC.
# FIXME it appears this version of tar has problems untarring tarballs
# created by the stock os x tar:
#   tar xzf /Users/macuser/Downloads/gzip-1.11.tar.gz
#   tar: gzip-1.11/tests: Cannot utime: Invalid argument
#   tar: gzip-1.11: Cannot utime: Invalid argument
#   tar: Exiting with failure status due to previous errors
# There is only one google hit for this exact error:
#   https://bugs.launchpad.net/ubuntu/+source/linux-meta-hwe/+bug/1820499

package=tar
version=1.34
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gettext-0.20$ppc64 ; then
    tiger.sh gettext-0.20$ppc64
fi

if ! test -e /opt/libiconv-1.16$ppc64 ; then
    tiger.sh libiconv-1.16$ppc64
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --os.cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

if test -n "$ppc64" ; then
    CFLAGS="-m64 $(tiger.sh -mcpu -O)"
    export LDFLAGS=-m64
else
    CFLAGS=$(tiger.sh -m32 -mcpu -O)
fi
export CFLAGS

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-libiconv-prefix=/opt/libiconv-1.16$ppc64 \
    --with-libintl-prefix=/opt/gettext-0.20$ppc64

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
