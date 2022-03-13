#!/bin/bash

# Install gcc 4.2 from tigerbrew.

package=gcc
version=4.2
upstream=https://archive.org/download/tigerbrew/gcc-42-5553-darwin8-all.tar.gz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

pkgspec=$package-$version

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if which -s gcc-4.2 ; then
    echo "gcc-4.2 is already installed." >&2
    exit 0
fi

tarball=gcc-42-5553-darwin8-all.tar.gz

echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /." >&2
url=$LEOPARDSH_MIRROR/dist/$tarball
leopard.sh --unpack-tarball-check-md5 $url / sudo
