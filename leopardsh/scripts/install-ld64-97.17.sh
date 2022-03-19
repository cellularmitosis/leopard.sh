#!/opt/tigersh-deps-0.1/bin/bash

# Install ld64 97.17 from tigerbrew, see https://github.com/mistydemeo/tigerbrew

package=ld64
version=97.17
upstream=https://archive.org/download/tigerbrew/ld64-97.17.tiger_g3.bottle.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

pkgspec=$package-$version

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if test -e /opt/$pkgspec/bin/ld >/dev/null 2>&1 ; then
    echo "$pkgspec is already installed." >&2
    exit 0
fi

tarball=ld64-97.17.tiger_g3.bottle.tar.gz

echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /tmp." >&2
url=$upstream

tiger.sh --unpack-tarball-check-md5 $url /tmp 1635b8ee2c700d40fa8ecd6ea0ee9218

mkdir -p /opt/$pkgspec
rsync -a /tmp/ld64/97.17/ /opt/$pkgspec/

# thanks misty!
