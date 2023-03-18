#!/bin/bash

# Install Perian QuickTime component 1.2.3 on OS X Leopard / PowerPC.

set -e -o pipefail

pkgspec=perian-1.2.3

if test -e /Library/PreferencePanes/Perian.prefpane/Contents/Info.plist ; then
    installed_version=$( cat /Library/PreferencePanes/Perian.prefpane/Contents/Info.plist \
        | grep -A1 CFBundleVersion \
        | head -n2 \
        | tail -n1 \
        | perl -pe 's/.*>(.*)<.*/$1/'
    )
    if test "$installed_version" = "1.2.3" ; then
        echo -e "${COLOR_YELLOW}${pkgspec}${COLOR_NONE} is already installed." >&2
        touch /opt/$pkgspec/SUPERFLUOUS_DIRECTORY
        exit 0
    fi
fi

leopard.sh --unpack-dist $pkgspec.tiger.g4
open /tmp/$pkgspec/Perian.prefpane
echo "Please use the on-screen dialog to install Perian." >&2
echo "Afterwards, try running your leopard.sh command again." >&2
rm -rf /opt/$pkgspec
exit 1
