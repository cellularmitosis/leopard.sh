#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# Install ZDoom.app on OS X / PowerPC.

package=zdoom.app
version=2.8.1
appname1=ZDoom
upstream=https://zdoom.org/files/zdoom/2.8/zdoom-2.8.1.dmg

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

pkgspec=$package-$version

osversion=$(sw_vers -productVersion | awk '{print $NF}')
if test "${osversion:0:4}" = "10.4" ; then
    pkgmgr="tiger.sh"
    mirror=$TIGERSH_MIRROR
elif test "${osversion:0:4}" = "10.5" ; then
    pkgmgr="leopard.sh"
    mirror=$LEOPARDSH_MIRROR
fi
test -n "$pkgmgr"

if ! test -e /opt/doom-shareware-wad-1.9 ; then
    $pkgmgr doom-shareware-wad-1.9
fi

echo -n -e "\033]0;$pkgmgr $pkgspec ($($pkgmgr --cpu))\007"

tarball=$pkgspec.tar.gz
url=$mirror/dist/$tarball
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

if ! test -e "$HOME/Library/Application Support/zdoom/doom1.wad" ; then
    mkdir -p "$HOME/Library/Application Support/zdoom"
    ln -s /opt/doom-shareware-wad-1.9/share/doom/doom1.wad "$HOME/Library/Application Support/zdoom/"
fi

