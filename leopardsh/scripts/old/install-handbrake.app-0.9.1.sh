#!/bin/bash
# based on templates/install-app-from-dmg.sh v1

# Install Handbrake.app on OS X / PowerPC.

package=handbrake.app
appname=Handbrake
version=0.9.1
mountpoint="/Volumes/$appname"

set -e -x
PATH="/opt/tigersh-deps-0.1/bin:$PATH"

pkgspec=$package-$version

srcmirror=https://www.videohelp.com/download
zip=$appname-$version.zip

# Note: this is probably a "referrer" param and this URL will likely break for
# other folks. If so, visit https://www.videohelp.com/software?d=HandBrake-0.9.1.zip
# and download it manually into ~/Downloads, then try again.
query='?r=gLmZQDCBkKg'

if ! test -e ~/Downloads/$zip ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$zip$query
fi

cd /tmp
unzip -q ~/Downloads/$zip

dmg=$appname-$version-MacOSX.4_GUI_UB.dmg

test "$(md5 $dmg | awk '{print $NF}')" = f6d3c9366a6d1eaa21c175f966df6765

hdiutil attach -readonly -noverify -noautofsck -noautoopen $dmg

mkdir -p /opt/$pkgspec

# Note: rsyncing the entire mountpoint would fail:
#     rsync: opendir "/Volumes/Foo-1.0/.Trashes" failed: Permission denied (13)
# So we rsync $mountpoint/* instead.
rsync -a "$mountpoint"/* /opt/$pkgspec/

hdiutil detach "$mountpoint" || true

# Create aliases in /Applications (must be aliases, symlinks don't work).
# Note: if we call this too soon after the rsync, it will fail with:
#     29:124: execution error: Finder got an error: The operation could not be completed. (-1407)
# So we try it a few times until it succeeds.  So gross!
for i in 1 2 3 4 5 ; do
    aliasname=$(
        osascript -e "tell application \"Finder\" to make alias file to POSIX file \"/opt/$pkgspec/$appname.app\" at POSIX file \"/opt/$pkgspec\"" || true
    )
    if test -z "$aliasname" ; then
        sleep 1
        continue
    fi
    aliasname=$( echo $aliasname | sed 's/^alias file //' )
    rm -f "/Applications/$appname $version"
    mv "/opt/$pkgspec/$aliasname" "/Applications/$appname $version"
    break
done
