#!/opt/tigersh-deps-0.1/bin/bash

# Install Xcode 2.5 on OS X Tiger / PowerPC.

set -e -o pipefail

pkgspec=xcode-2.5

if test -e /Developer/Applications/Xcode.app/Contents/version.plist ; then
    installed_version=$( cat /Developer/Applications/Xcode.app/Contents/version.plist \
        | grep -A1 CFBundleShortVersionString \
        | tail -n1 \
        | perl -pe 's/.*>(.*)<.*/$1/'
    )
    if test "$installed_version" = "2.5" ; then
        echo -e "${COLOR_YELLOW}${pkgspec}${COLOR_NONE} is already installed." >&2
        touch /opt/$pkgspec/SUPERFLUOUS_DIRECTORY
        exit 0
    fi
fi

tiger.sh --unpack-dist $pkgspec
open /tmp/$pkgspec/Installers/Xcode\ Installer\ Launcher.app
echo "Please use the on-screen dialog to install Xcode." >&2
echo "Afterwards, try running your tiger.sh command again." >&2
rm -rf /opt/$pkgspec
exit 1
