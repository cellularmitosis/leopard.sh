#!/opt/tigersh-deps-0.1/bin/bash

# Install Flip4Mac WMV 2.3.8.1 on OS X Tiger / PowerPC.

set -e -o pipefail

pkgspec=flip4mac-2.3.8.1

if test -e /Library/QuickTime/Flip4Mac\ WMV\ Import.component/Contents/Info.plist ; then
    installed_version=$( cat /Library/QuickTime/Flip4Mac\ WMV\ Import.component/Contents/Info.plist \
        | grep -A1 CFBundleShortVersionString \
        | tail -n1 \
        | perl -pe 's/.*>(.*)<.*/$1/'
    )
    if test "$installed_version" = "2.3.8.1" ; then
        echo -e "${COLOR_YELLOW}${pkgspec}${COLOR_NONE} is already installed." >&2
        touch /opt/$pkgspec/SUPERFLUOUS_DIRECTORY
        exit 0
    fi
fi

tiger.sh --unpack-dist $pkgspec.tiger
open /tmp/$pkgspec/Flip4Mac\ WMV.mpkg
echo "Please use the on-screen dialog to install Flip4Mac WMV." >&2
echo "Afterwards, try running your tiger.sh command again." >&2
rm -rf /opt/$pkgspec
exit 1
