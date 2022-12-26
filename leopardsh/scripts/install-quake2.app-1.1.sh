#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# Install Quake II.app on OS X / PowerPC.

package=quake2.app
version=1.1
upstream=http://macintoshgarden.org/sites/macintoshgarden.org/files/games/Quake2-11.dmg
appname1="Quake II"

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

if ! test -e /opt/quake2-pak0.pak-3.14 ; then
    $pkgmgr quake2-pak0.pak-3.14
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

# Use the pak0.pak which we symlinked into ~/.quake2/baseq2/.
defaults write com.fruitz-of-dojo.quake2 "Quake II baseq2 Path" "$HOME/.quake2/baseq2"

mkdir -p ~/.quake2/baseq2
ln -s "/opt/$pkgspec/Into 'baseq2' folder/GameMac.q2plug" ~/.quake2/baseq2/

# Start off with some popular config settings.
# Note: negative m_pitch means "invert mouse".
# Note: "impules 10" means "next weapon".
# Note: cl_backspeed, cl_backspeed mean "always run".
if ! test -e ~/.quake2/baseq2/config.cfg ; then
    cat > ~/.quake2/baseq2/config.cfg << "EOF"
bind "w" "+forward"
bind "a" "+moveleft"
bind "s" "+back"
bind "d" "+moveright"
bind "SPACE" "+moveup"
bind "MOUSE1" "+attack"
bind "MOUSE2" "+moveup"
bind "MWHEELDOWN" "weapnext"
set m_pitch "-0.022"
set vid_ref "gl"
set gl_driver "opengl32"
set gl_mode "5"
set cl_run "1"
set freelook "1"
set sensitivity "8.5"
EOF
fi
