#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install clisp on OS X Tiger / PowerPC.

package=clisp
version=2.49.93.20230212
# upstream=https://gitlab.com/gnu-clisp/clisp/-/archive/master/clisp-master.tar.gz
commit=79cbafdbc6337d6dcd8f2dbad69fb7ebf7a46012
upstream=https://gitlab.com/gnu-clisp/clisp/-/archive/$commit/$package-$commit.tar.gz
description="An ANSI Common Lisp implementation in C"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/hyperspec-7.0 ; then
    tiger.sh hyperspec-7.0
fi

for dep in \
    gettext-0.20$ppc64 \
    libiconv-bootstrap-1.16$ppc64 \
    libsigsegv-2.14$ppc64 \
    libunistring-1.0$ppc64 \
    readline-8.2$ppc64
    # lightning-2.1.3$ppc64
    # Note: libffcall not available on tiger yet.
    # libffcall-2.4$ppc64
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

if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.2
fi
CC=gcc-4.2

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --disable-maintainer-mode \
    --disable-debug \
    --with-unicode \
    --with-threads=POSIX_THREADS \
    --hyperspec=file:///opt/hyperspec-7.0/HyperSpec \
    --with-libiconv-prefix=/opt/libiconv-bootstrap-1.16$ppc64 \
    --with-libintl-prefix=/opt/gettext-0.20$ppc64 \
    --with-libreadline-prefix=/opt/readline-8.2$ppc64 \
    --with-libsigsegv-prefix=/opt/libsigsegv-2.14$ppc64 \
    --with-libunistring-prefix=/opt/libunistring-1.0$ppc64 \
        --with-module=asdf \
        --with-module=editor \
        --with-module=syscalls \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CC="$CC"

    # --with-ffcall \
    # --with-libffcall-prefix=/opt/libffcall-2.4$ppc64 \

        # --with-module=berkeley-db \
        # --with-module=bindings/glibc \
        # --with-module=bindings/win32 \
        # --with-module=clx/mit-clx \
        # --with-module=clx/new-clx \
        # --with-module=dbus \
        # --with-module=dirkey \
        # --with-module=fastcgi \
        # --with-module=gdbm \
        # --with-module=gtk2 \
        # --with-module=i18n \
        # --with-module=libsvm \
        # --with-module=matlab \
        # --with-module=netica \
        # --with-module=oracle \
        # --with-module=pari \
        # --with-module=pcre \
        # --with-module=postgresql \
        # --with-module=queens \
        # --with-module=rawsock \
        # --with-module=readline \
        # --with-module=regexp \
        # --with-module=zlib \

    # --with-jitc=lightning
    # --with-lightning-prefix=/opt/lightning-2.1.3$ppc64 \

cd src
./makemake \
    --prefix=/opt/$pkgspec \
    > Makefile

make config.lisp

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
