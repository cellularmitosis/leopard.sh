#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app-from-dmg.sh v1

# 👇 EDIT HERE:
# Install Foo.app on OS X / PowerPC.

# 👇 EDIT HERE:
package=foo.app
appname=Foo
version=1.0
mountpoint="/Volumes/$appname $version"

set -e -o pipefail
set -x
PATH="/opt/tigersh-deps-0.1/bin:$PATH"

pkgspec=$package-$version

# 👇 EDIT HERE:
srcmirror=https://ccl.clozure.com/ftp/pub/release/$version
# 👇 EDIT HERE:
dmg=${appname}_$version.dmg

if ! test -e ~/Downloads/$dmg ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$dmg
fi

# 👇 EDIT HERE:
test "$(md5 ~/Downloads/$dmg | awk '{print $NF}')" = xxxxxxxzxxxxxxxxxxzxxxxxxxxxxzxx

hdiutil attach -readonly -noverify -noautofsck -noautoopen ~/Downloads/$dmg

mkdir -p /opt/$pkgspec

# Note: rsyncing the entire mountpoint would fail:
#     rsync: opendir "/Volumes/Foo-1.0/.Trashes" failed: Permission denied (13)
# So we rsync $mountpoint/* instead.
rsync -a "$mountpoint"/* /opt/$pkgspec/

hdiutil detach "$mountpoint" || true

# 👇 EDIT HERE:
defaults write com.foo "Some Setting" "Some Value"

# Create aliases in /Applications (must be aliases, symlinks don't work).
# Thanks to https://stackoverflow.com/a/10067437
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

# 👇 EDIT HERE:
# Thanks to https://stackoverflow.com/a/13484552
$( osascript \
    -e 'tell application "Finder"' \
    -e 'activate' \
    -e 'display dialog "Here is a way to tell the user something." buttons {"OK"} default button 1' \
    -e 'end tell'\
    >/dev/null 2>&1 \
    &
)
