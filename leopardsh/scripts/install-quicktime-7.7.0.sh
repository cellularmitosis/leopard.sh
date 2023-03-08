#!/bin/bash

# Install quicktime 7.7.0 on OS X Leopard / PowerPC.

set -e -o pipefail

pkgspec=quicktime-7.7.0

if test -e /Applications/QuickTime\ Player.app/Contents/version.plist ; then
    installed_version=$( cat /Applications/QuickTime\ Player.app/Contents/version.plist \
        | grep -A1 CFBundleShortVersionString \
        | tail -n1 \
        | perl -pe 's/.*>(.*)<.*/$1/'
    )
    if test "$installed_version" = "7.7" ; then
        echo -e "${COLOR_YELLOW}${pkgspec}${COLOR_NONE} is already installed." >&2
        touch /opt/$pkgspec/SUPERFLUOUS_DIRECTORY
        exit 0
    fi
fi

leopard.sh --unpack-dist $pkgspec.leopard
open /tmp/$pkgspec.leopard/QuickTime770_Leopard.pkg
echo "Please use the on-screen dialog to install QuickTime." >&2
echo "Afterwards, try running your leopard.sh command again." >&2
rm -rf /opt/$pkgspec
exit 1
