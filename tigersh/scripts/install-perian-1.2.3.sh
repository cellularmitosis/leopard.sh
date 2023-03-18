#!/opt/tigersh-deps-0.1/bin/bash

# Install Perian QuickTime component 1.2.3 on OS X Leopard / PowerPC.

set -e -o pipefail

package=perian
version=1.2.3
if test "$(tiger.sh --cpu)" = "g3" ; then
    # Apparently 1.2.3 has issues on G3 processors.
    # See https://macintoshgarden.org/apps/perian
    version=1.2
fi
pkgspec=$package-$version

if test -e /Library/PreferencePanes/Perian.prefpane/Contents/Info.plist ; then
    installed_version=$( cat /Library/PreferencePanes/Perian.prefpane/Contents/Info.plist \
        | grep -A1 CFBundleVersion \
        | head -n2 \
        | tail -n1 \
        | perl -pe 's/.*>(.*)<.*/$1/'
    )
    if test "$installed_version" = "1.2" ; then
        echo -e "${COLOR_YELLOW}${pkgspec}${COLOR_NONE} is already installed." >&2
        touch /opt/$package-1.2.3/SUPERFLUOUS_DIRECTORY
        exit 0
    fi
fi

if test "$(tiger.sh --cpu)" = "g3" ; then
    tiger.sh --unpack-dist $pkgspec.tiger.g3
else
    tiger.sh --unpack-dist $pkgspec.tiger.g4
fi
open /tmp/$pkgspec/Perian.prefpane
echo "Please use the on-screen dialog to install Perian." >&2
echo "Afterwards, try running your leopard.sh command again." >&2
rm -rf /opt/$pkgspec
exit 1
