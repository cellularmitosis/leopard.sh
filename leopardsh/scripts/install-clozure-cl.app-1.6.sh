#!/bin/bash
# based on templates/install-app-from-dmg.sh v1

# Install Clozure CL.app on OS X / PowerPC.

package=clozure-cl.app
appname1="Clozure CL32"
appname1="Clozure CL64"
version=1.6
mountpoint=/Volumes/ccl

set -e -x
PATH="/opt/portable-curl/bin:$PATH"

pkgspec=$package-$version

# Note: there are two types of downloads available:
# - ccl-1.4-darwinppc.dmg
# - ccl-1.4-darwinppc.tar.gz
# The .dmg contains a GUI IDE .app which the tarball does not.

srcmirror=https://ccl.clozure.com/ftp/pub/release/$version
dmg=ccl-$version-darwinppc.dmg

if ! test -e ~/Downloads/$dmg ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$dmg
fi

test "$(md5 ~/Downloads/$dmg | awk '{print $NF}')" = c59321565544884f68868bae6270e3ce

hdiutil attach -readonly -noverify -noautofsck -noautoopen ~/Downloads/$dmg

mkdir -p /opt/$pkgspec

# Note: rsyncing the entire mountpoint would fail:
#     rsync: opendir "/Volumes/Foo-1.0/.Trashes" failed: Permission denied (13)
# So we rsync $mountpoint/* instead.
rsync -a "$mountpoint"/* /opt/$pkgspec/

hdiutil detach "$mountpoint" || true

# Create aliases in /Applications (must be aliases, symlinks don't work).
for appname in "$appname1" "$appname2" ; do
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
done

for f in ccl ccl64 ; do
    perl -pi \
        -e "s|CCL_DEFAULT_DIRECTORY=/usr/local/src/ccl|CCL_DEFAULT_DIRECTORY=/opt/$pkgspec|" \
        /opt/$pkgspec/scripts/$f
done

mkdir -p /opt/$pkgspec/bin
cd /opt/$pkgspec/bin
for f in ccl ccl64 ; do
    ln -s ../scripts/$f .
done

ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
