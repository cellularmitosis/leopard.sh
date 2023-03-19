#!/bin/bash

# Install Flip4Mac WMV 2.4.4.2 on OS X Leopard / PowerPC.

set -e -o pipefail

pkgspec=flip4mac-2.4.4.2

if test -e /Library/QuickTime/Flip4Mac\ WMV\ Import.component/Contents/Info.plist ; then
    installed_version=$( cat /Library/QuickTime/Flip4Mac\ WMV\ Import.component/Contents/Info.plist \
        | grep -A1 CFBundleShortVersionString \
        | tail -n1 \
        | perl -pe 's/.*>(.*)<.*/$1/'
    )
    if test "$installed_version" = "2.4.4.2" ; then
        echo -e "${COLOR_YELLOW}${pkgspec}${COLOR_NONE} is already installed." >&2
        touch /opt/$pkgspec/SUPERFLUOUS_DIRECTORY
        exit 0
    fi
fi

leopard.sh --unpack-dist $pkgspec.leopard
open /tmp/$pkgspec/Flip4Mac\ WMV.mpkg
echo "Please use the on-screen dialog to install Flip4Mac WMV." >&2
echo "Afterwards, try running your leopard.sh command again." >&2
rm -rf /opt/$pkgspec
exit 1
