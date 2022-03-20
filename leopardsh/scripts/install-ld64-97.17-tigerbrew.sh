#!/opt/tigersh-deps-0.1/bin/bash

# Install ld64 97.17 from tigerbrew, see https://github.com/mistydemeo/tigerbrew

package=ld64
version=97.17-tigerbrew
upstream=https://archive.org/download/tigerbrew/ld64-97.17.tiger_g3.bottle.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

pkgspec=$package-$version

osversion=$(sw_vers -productVersion | awk '{print $NF}')
if test "${osversion:0:4}" = "10.4" ; then
    pkgmgr="tiger.sh"
    mirror=$TIGERSH_MIRROR
elif test "${osversion:0:4}" = "10.5" ; then
    pkgmgr="leopard.sh"
    mirror=$LEOPARDSH_MIRROR
fi
test -n "$pkgmgr"

echo -n -e "\033]0;$pkgmgr $pkgspec ($($pkgmgr --cpu))\007"

if test -e /opt/$pkgspec/bin/ld >/dev/null 2>&1 ; then
    echo "$pkgspec is already installed." >&2
    exit 0
fi

tarball=ld64-97.17.tiger_g3.bottle.tar.gz

echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /tmp." >&2
url=$upstream

$pkgmgr --unpack-tarball-check-md5 $url /tmp 1635b8ee2c700d40fa8ecd6ea0ee9218

mkdir -p /opt/$pkgspec
rsync -a /tmp/ld64/97.17/ /opt/$pkgspec/

# thanks misty!
