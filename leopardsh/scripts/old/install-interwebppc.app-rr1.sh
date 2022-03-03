#!/bin/bash
# based on templates/install-app-from-dmg.sh v1

# Install InterWebPPC.app on OS X / PowerPC.

package=interwebppc.app
appname=InterWebPPC
version=rr1
ucversion=RR1
mountpoint=/Volumes/Foo

set -e -x
PATH="/opt/portable-curl/bin:$PATH"

pkgspec=$package-$version

srcmirror=https://github.com/wicknix/$appname/releases/download/$ucversion

cpu_id=$(sysctl hw.cpusubtype | awk '{print $NF}')
if test "$cpu_id" = "9" ; then
    cpu=G3
elif test "$cpu_id" = "10" -o "$cpu_id" = "11" ; then
    cpu=G4
elif test "$cpu_id" = "100" ; then
    cpu=G5
fi
test -n "$cpu"

zip=$appname-$ucversion-$cpu.zip

if ! test -e ~/Downloads/$zip ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$zip
fi

if test "$cpu" = "G3" ; then
    md5=83a6581a44d21518ad2f21d959679742
elif test "$cpu" = "G4" ; then
    md5=ccc9e8c3b6bca46334e2f076ca059929
elif test "$cpu" = "G5" ; then
    md5=187e8998371ee37374f32440825b6095
fi

test "$(md5 ~/Downloads/$zip | awk '{print $NF}')" = $md5

mkdir -p /opt/$pkgspec

cd /opt/$pkgspec
unzip -q ~/Downloads/$zip

mv $appname-$cpu.app $appname.app

mkdir -p bin
cd bin
for f in js xpcshell ; do
    ln -s ../$appname.app/Contents/MacOS/$f .
done

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
    rm -f "/Applications/$appname $ucversion"
    mv "/opt/$pkgspec/$aliasname" "/Applications/$appname $ucversion"
    break
done

ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
