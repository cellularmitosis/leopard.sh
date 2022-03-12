#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# 👇 EDIT HERE:
# Install Foo.app on OS X / PowerPC.

# 👇 EDIT HERE:
package=foo.app
version=1.0
upstream=https://ccl.clozure.com/ftp/pub/release/$version/${appname}_$version.dmg
appname1=Foo

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

pkgspec=$package-$version

osversion=$(sw_vers -productVersion | awk '{print $NF}')
if test "${osversion:0:4}" = "10.4" ; then
    pkgmgr="tiger.sh"
elif test "${osversion:0:4}" = "10.5" ; then
    pkgmgr="leopard.sh"
fi
test -n "$pkgmgr"

echo -n -e "\033]0;$pkgmgr $pkgspec ($($pkgmgr --cpu))\007"

tarball=$pkgspec.tar.gz
url=$LEOPARDSH_MIRROR/dist/$tarball
echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /opt." >&2
$pkgmgr --unpack-tarball-check-md5 $url /opt

echo -e "${COLOR_CYAN}Creating${COLOR_NONE} aliases for $pkgspec." >&2
for appname in "$appname1" ; do
    # Note: these must be aliases, symlinks don't work.
    # Note: if we call this too soon after unpacking, it will fail with:
    #     29:124: execution error: Finder got an error: The operation could not be completed. (-1407)
    # So we try it a few times until it succeeds.  So gross!
    for i in 1 2 3 4 5 ; do
        aliasname=$(
            osascript -e "tell application \"Finder\" to make alias file to POSIX file \"/opt/$pkgspec/$appname.app\" at POSIX file \"/opt/$pkgspec\"" 2>/dev/null || true
        )
        if test -z "$aliasname" ; then
            sleep 1
            continue
        fi
        aliasname=$( echo $aliasname | sed 's/^alias file //' )
        rm -f "/Applications/$appname $version"
        mv "/opt/$pkgspec/$aliasname" "/Applications/$appname $version"
        echo "  \"/Applications/$appname $version\" -> /opt/$pkgspec/$appname"
        break
    done
done

# 👇 EDIT HERE:
defaults write com.foo "Some Setting" "Some Value"

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
