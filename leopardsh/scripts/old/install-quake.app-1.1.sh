#!/bin/bash
# based on templates/install-app-from-dmg.sh v1

# Install Quake.app on OS X / PowerPC.

package=quake.app
appname1="Quake"
appname2="GLQuake"
appname3="QuakeWorld"
appname4="GLQuakeWorld"
version=1.1
mountpoint="/Volumes/$appname1 v$version"

set -e -x
PATH="/opt/tigersh-deps-0.1/bin:$PATH"

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

srcmirror=https://macintoshgarden.org/sites/macintoshgarden.org/files/games
zip=${appname1}v$version.dmg_.zip

if ! test -e ~/Downloads/$zip ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$zip$query
fi

test "$(md5 ~/Downloads/$zip | awk '{print $NF}')" = c90cfed90bbceb584a30e6b955cf75dc

dmg=${appname1}v$version.dmg

tmp=$(mktemp -d /tmp/.zip.XXXXXX)
cd $tmp
unzip -q ~/Downloads/$zip

hdiutil attach -readonly -noverify -noautofsck -noautoopen $dmg

mkdir -p /opt/$pkgspec

# Note: rsyncing the entire mountpoint would fail:
#     rsync: opendir "/Volumes/Foo-1.0/.Trashes" failed: Permission denied (13)
# So we rsync $mountpoint/* instead.
rsync -a "$mountpoint"/* /opt/$pkgspec/

hdiutil detach "$mountpoint" || true

# Create aliases in /Applications (must be aliases, symlinks don't work).
for appname in "$appname1" "$appname2" "$appname3" "$appname4" ; do
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

mkdir -p /opt/$pkgspec/bin
cd /opt/$pkgspec/bin
ln -s ../qwsv .

ln -sf /opt/$pkgspec/bin/* /usr/local/bin/

rm -rf $tmp

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
