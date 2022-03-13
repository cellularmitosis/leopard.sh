#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# Install InterWebPPC.app on OS X / PowerPC.

package=interwebppc.app
version=rr1
ucversion=RR1
appname1=InterWebPPC
upstream_g3=https://github.com/wicknix/InterWebPPC/releases/download/RR1/InterWebPPC-RR1-G3.zip
upstream_g4=https://github.com/wicknix/InterWebPPC/releases/download/RR1/InterWebPPC-RR1-G4.zip
upstream_g5=https://github.com/wicknix/InterWebPPC/releases/download/RR1/InterWebPPC-RR1-G5.zip

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

cpu_id=$(sysctl hw.cpusubtype | awk '{print $NF}')
if test "$cpu_id" = "9" ; then
    cpu=g3
elif test "$cpu_id" = "10" -o "$cpu_id" = "11" ; then
    cpu=g4
elif test "$cpu_id" = "100" ; then
    cpu=g5
fi
test -n "$cpu"

echo -n -e "\033]0;$pkgmgr $pkgspec ($($pkgmgr --cpu))\007"

tarball=$pkgspec.$cpu.tar.gz
url=$mirror/dist/$tarball
echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /opt." >&2
$pkgmgr --unpack-tarball-check-md5 $url /opt

mkdir -p bin
cd bin
for f in js xpcshell ; do
    ln -s ../$appname.app/Contents/MacOS/$f .
done

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
        rm -f "/Applications/$appname $ucversion"
        mv "/opt/$pkgspec/$aliasname" "/Applications/$appname $ucversion"
        echo "  \"/Applications/$appname $version\" -> /opt/$pkgspec/$appname"
        break
    done
done
