#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install SPIM on OS X Tiger / PowerPC.

package=spim
version=r754
upstream=https://sourceforge.net/code-snapshots/svn/s/sp/spimsimulator/code/spimsimulator-code-r754.zip
description="MIPS CPU simulator"

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

# Tiger's bison is too old.
#   bison: option `--defines' doesn't allow an argument
if ! test -e /opt/bison-3.8.2 ; then
    tiger.sh bison-3.8.2
fi
export PATH="/opt/bison-3.8.2/bin:$PATH"

# Tiger's flex is too old.
#   flex: can't open lex.yy.cpp
if ! test -e /opt/flex-2.6.4 ; then
    tiger.sh flex-2.6.4
fi
export PATH="/opt/flex-2.6.4/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

cd spim
make PREFIX=/opt/spim-r754 install
if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make test
fi
cd -

cd xspim
make PREFIX=/opt/spim-r754 EXTRA_LDOPTIONS="-L/usr/X11R6/lib -lstdc++" install
cd -

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
