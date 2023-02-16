#!/opt/tigersh-deps-0.1/bin/bash

# Install gcc (libraries only) on OS X Tiger / PowerPC.

package=gcc-libs
version=4.9.4
upstream=https://ftp.gnu.org/gnu/$package/$package-$version/$package-$version.tar.gz
description="The GNU compiler collection (4.9.4 supports C11 and thread-local storage)"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

src_pkgspec=gcc-$version$ppc64
dest_pkgspec=$pkgspec

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    if ! test -e /opt/$src_pkgspec ; then
        cd /opt
        ln -s $dest_pkgspec $src_pkgspec
    fi
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec." >&2
set -x

if ! test -e /opt/$src_pkgspec ; then
    tiger.sh --install-binpkg $src_pkgspec
fi

mkdir -p /opt/$dest_pkgspec
rsync -a /opt/$src_pkgspec/lib /opt/$dest_pkgspec/

for pkgmgr in tiger.sh leopard.sh ; do
    if test -e /opt/$dest_pkgspec/share/$pkgmgr ; then
        mkdir -p /opt/$dest_pkgspec/share
        rsync -a /opt/$src_pkgspec/lib/$pkgmgr /opt/$dest_pkgspec/share/
    fi
done

tiger.sh --linker-check $dest_pkgspec
tiger.sh --arch-check $dest_pkgspec $ppc64
