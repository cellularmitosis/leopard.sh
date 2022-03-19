#!/opt/tigersh-deps-0.1/bin/bash

# Install gcc 4.2 from tigerbrew, see https://github.com/mistydemeo/tigerbrew

package=gcc
version=4.2
upstream=https://archive.org/download/tigerbrew/gcc-42-5553-darwin8-all.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

pkgspec=$package-$version

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if type -a gcc-4.2 >/dev/null 2>&1 ; then
    echo "gcc-4.2 is already installed." >&2
    exit 0
fi

tarball=gcc-42-5553-darwin8-all.tar.gz

echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /." >&2
url=$upstream
tiger.sh --unpack-tarball-check-md5 $url / sudo b12cdbef3c73af31674851f04c3b234b

# thanks misty!
