#!/opt/tigersh-deps-0.1/bin/bash

# Install MacTeX 2010 on OS X Tiger / PowerPC.

set -e -o pipefail

pkgspec=mactex-2010

if test -e /usr/local/texlive/2010 ; then
    echo -e "${COLOR_YELLOW}${pkgspec}${COLOR_NONE} is already installed." >&2
    touch /opt/$pkgspec/SUPERFLUOUS_DIRECTORY
    exit 0
fi

tiger.sh --unpack-dist $pkgspec.tiger
open /tmp/$pkgspec/MacTex-2010.mpkg
echo "Please use the on-screen dialog to install MacTeX." >&2
echo "Afterwards, try running your tiger.sh command again." >&2
rm -rf /opt/$pkgspec
exit 1
