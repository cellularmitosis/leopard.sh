#!/bin/bash

# Install the QuickTime MPEG-2 component 6.4.1 on OS X Leopard / PowerPC.

set -e -o pipefail

pkgspec=quicktime-mpeg2-6.4.1

if test -e /System/Library/QuickTime/QuickTimeMPEG2.component/Contents/version.plist ; then
    installed_version=$( cat /System/Library/QuickTime/QuickTimeMPEG2.component/Contents/version.plist \
        | grep -A1 CFBundleShortVersionString \
        | tail -n1 \
        | perl -pe 's/.*>(.*)<.*/$1/'
    )
    if test "$installed_version" = "6.4.1" ; then
        echo -e "${COLOR_YELLOW}${pkgspec}${COLOR_NONE} is already installed." >&2
        touch /opt/$pkgspec/SUPERFLUOUS_DIRECTORY
        exit 0
    fi
fi

leopard.sh --unpack-dist $pkgspec
open /tmp/$pkgspec/QuickTimeMPEG2Pro.pkg
echo "Please use the on-screen dialog to install the QuickTime MPEG-2 component." >&2
echo "Afterwards, try running your leopard.sh command again." >&2
rm -rf /opt/$pkgspec
exit 1
