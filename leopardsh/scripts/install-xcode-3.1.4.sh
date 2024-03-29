#!/bin/bash

# Install Xcode 3.1.4 on OS X Leopard / PowerPC.

set -e -o pipefail

pkgspec=xcode-3.1.4

if test -e /Developer/Applications/Xcode.app/Contents/version.plist ; then
    installed_version=$( cat /Developer/Applications/Xcode.app/Contents/version.plist \
        | grep -A1 CFBundleShortVersionString \
        | tail -n1 \
        | perl -pe 's/.*>(.*)<.*/$1/'
    )
    if test "$installed_version" = "3.1.4" ; then
        echo -e "${COLOR_YELLOW}${pkgspec}${COLOR_NONE} is already installed." >&2
        touch /opt/$pkgspec/SUPERFLUOUS_DIRECTORY
        exit 0
    fi
fi

leopard.sh --unpack-dist $pkgspec
open /tmp/$pkgspec/XcodeTools.mpkg
echo "Please use the on-screen dialog to install Xcode." >&2
echo "Afterwards, try running your leopard.sh command again." >&2
rm -rf /opt/$pkgspec
exit 1
