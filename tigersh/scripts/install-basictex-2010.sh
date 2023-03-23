#!/opt/tigersh-deps-0.1/bin/bash

# Install BasicTeX 2010 on OS X Tiger / PowerPC.

set -e -o pipefail

pkgspec=basictex-2010

if test -e /usr/local/texlive/2010basic ; then
    echo -e "${COLOR_YELLOW}${pkgspec}${COLOR_NONE} is already installed." >&2
    touch /opt/$pkgspec/SUPERFLUOUS_DIRECTORY
    exit 0
fi

tiger.sh --unpack-dist $pkgspec.tiger
open /tmp/$pkgspec/BasicTex-2010.pkg
echo "Please use the on-screen dialog to install BasicTeX." >&2
echo "Afterwards, try running your tiger.sh command again." >&2
rm -rf /opt/$pkgspec
exit 1
