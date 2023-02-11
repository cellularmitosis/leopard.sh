#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install git on OS X Tiger / PowerPC.

package=git
version=2.35.1
upstream=https://www.kernel.org/pub/software/scm/git/git-$version.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    curl-7.87.0$ppc64 \
    expat-2.5.0$ppc64 \
    libiconv-1.16$ppc64 \
    libressl-3.4.2$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
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
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# Note: git on Tiger PPC when compiled with older compilers (e.g. gcc-4.2)
# will create SHA1 routines with the wrong endianness, resulting in errors:
#   $ git clone https://github.com/cellularmitosis/leopard.sh.git
#   Cloning into 'leopard.sh'...
#   remote: Enumerating objects: 4963, done.
#   remote: Counting objects: 100% (785/785), done.
#   remote: Compressing objects: 100% (173/173), done.
#   remote: Total 4963 (delta 624), reused 741 (delta 588), pack-reused 4178
#   Receiving objects: 100% (4963/4963), 4.34 MiB | 1.05 MiB/s, done.
#   fatal: pack is corrupted (SHA1 mismatch)
#   fatal: fetch-pack: invalid index-pack output
#
# See https://trac.macports.org/ticket/54602
# The easiest solution is -DSHA1DC_FORCE_BIGENDIAN=1.
CFLAGS="$CFLAGS -DSHA1DC_FORCE_BIGENDIAN=1"

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --with-openssl=/opt/libressl-3.4.2$ppc64 \
    --with-curl=/opt/curl-7.87.0$ppc64 \
    --with-iconv=/opt/libiconv-1.16$ppc64 \
    --with-expat=/opt/expat-2.5.0$ppc64 \
    CFLAGS="$CFLAGS" \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS"

# Using the stock gcc, configure ends up leaving CC_LD_DYNPATH empty, which
# causes linker errors, so we set it explicitly.
/usr/bin/time make $(tiger.sh -j) V=1 CC_LD_DYNPATH="-R"

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
