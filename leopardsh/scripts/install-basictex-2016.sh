#!/bin/bash

# Install BasicTeX on OS X Leopard / PowerPC.

set -e -o pipefail

pkgspec=basictex-2016

if test -e /usr/local/texlive/2010basic ; then
    echo -e "${COLOR_YELLOW}${pkgspec}${COLOR_NONE} is already installed." >&2
    touch /opt/$pkgspec/SUPERFLUOUS_DIRECTORY
    exit 0
fi

leopard.sh --unpack-dist $pkgspec.leopard
open /tmp/$pkgspec/mactex-basictex-20161009.pkg
echo "Please use the on-screen dialog to install BasicTeX." >&2
echo "Afterwards, try running your leopard.sh command again." >&2
rm -rf /opt/$pkgspec
exit 1
