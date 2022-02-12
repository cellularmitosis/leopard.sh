#!/bin/bash
# based on templates/install-app-from-zip.sh v1

# 👇 EDIT HERE:
# Install Foo.app on OS X / PowerPC.

# 👇 EDIT HERE:
package=foo.app
appname=Foo
version=1.0

set -e -x
PATH="/opt/portable-curl/bin:$PATH"

pkgspec=$package-$version

# 👇 EDIT HERE:
srcmirror=https://web.archive.org/web/20170331122430/http://arc.opera.com/pub/opera/mac/1063/
# 👇 EDIT HERE:
zip=${appname}_$version.zip

if ! test -e ~/Downloads/$zip ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$zip
fi

# 👇 EDIT HERE:
test "$(md5 ~/Downloads/$zip | awk '{print $NF}')" = xxxxxxxzxxxxxxxxxxzxxxxxxxxxxzxx

mkdir -p /opt/$pkgspec

cd /opt/$pkgspec
unzip -q ~/Downloads/$zip

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
