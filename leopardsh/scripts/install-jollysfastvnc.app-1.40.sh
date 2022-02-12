#!/bin/bash
# based on templates/install-app-from-dmg.sh v1

# Install JollysFastNVC.app on OS X / PowerPC.

# Speed comparison: https://www.jinx.de/Media/VNCcomparison-2.mp4

package=jollysfastvnc.app
appname=JollysFastVNC
version=1.40
mountpoint="/Volumes/$appname.$version.(1213706)"

set -e -x
PATH="/opt/portable-curl/bin:$PATH"

pkgspec=$package-$version

srcmirror=http://www.jinx.de/JollysFastVNC_files
dmg=$appname.current.10.4.dmg

if ! test -e ~/Downloads/$dmg ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$dmg
fi

test "$(md5 ~/Downloads/$dmg | awk '{print $NF}')" = 58feab203f09e7db2903929a4454c9af

hdiutil attach -readonly -noverify -noautofsck -noautoopen ~/Downloads/$dmg

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
