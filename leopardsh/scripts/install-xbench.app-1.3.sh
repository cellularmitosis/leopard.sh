#!/bin/bash
# based on templates/install-app-from-dmg.sh v1

# Install Foo.app on OS X / PowerPC.

package=xbench.app
appname=Xbench
version=1.3
mountpoint=/Volumes/$appname_$version

set -e -x
PATH="/opt/portable-curl/bin:$PATH"

pkgspec=$package-$version

srcmirror=http://www.xbench.com
dmg=${appname}_$version.dmg

if ! test -e ~/Downloads/$dmg ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$dmg
fi

test "$(md5 ~/Downloads/$dmg | awk '{print $NF}')" = d9b31d4fe479cc648eaab9f47a1c0c03

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
