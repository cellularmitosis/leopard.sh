#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# Install Quake.app on OS X / PowerPC.

package=quake.app
version=1.1
upstream=https://macintoshgarden.org/sites/macintoshgarden.org/files/games/${appname1}v$version.dmg_.zip
appname1="Quake"
appname2="GLQuake"
appname3="QuakeWorld"
appname4="GLQuakeWorld"

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

if ! test -e /opt/quake-pak0.pak-1.06 ; then
    $pkgmgr quake-pak0.pak-1.06
fi

echo -n -e "\033]0;$pkgmgr $pkgspec ($($pkgmgr --cpu))\007"

tarball=$pkgspec.tar.gz
url=$LEOPARDSH_MIRROR/dist/$tarball
echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /opt." >&2
$pkgmgr --unpack-tarball-check-md5 $url /opt

echo -e "${COLOR_CYAN}Creating${COLOR_NONE} aliases for $pkgspec." >&2
for appname in "$appname1" "$appname2" "$appname3" "$appname4" ; do
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

mkdir -p /opt/$pkgspec/bin
cd /opt/$pkgspec/bin
ln -s ../qwsv .

# Use the pak0.pak which we symlinked into ~/.quake/id1/.
defaults write com.fruitz-of-dojo.quake "Quake ID1 Path" "$HOME/.quake/id1"

# Default to "Millions of colors".
defaults write com.fruitz-of-dojo.quake "GLQuake Display Depth" 1

mkdir -p ~/.quake/id1

ln -sf /opt/$pkgspec/qw ~/.quake/

# Start off with some popular config settings.
# Note: negative m_pitch means "invert mouse".
# Note: "impules 10" means "next weapon".
# Note: cl_backspeed, cl_backspeed mean "always run".
if ! test -e ~/.quake/id1/config.cfg ; then
    cat > ~/.quake/id1/config.cfg << "EOF"
bind "w" "+forward"
bind "a" "+moveleft"
bind "s" "+back"
bind "d" "+moveright"
bind "SPACE" "+jump"
bind "MOUSE1" "+attack"
bind "MOUSE2" "+jump"
bind "MWHEELDOWN" "impulse 10"
bind "f" "impulse 10"
cl_backspeed "400"
cl_forwardspeed "400"
m_pitch "-0.022"
EOF
fi
