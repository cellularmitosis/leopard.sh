#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# Install InterWebPPC.app on OS X / PowerPC.

package=interwebppc.app
version=rr3
ucversion=RR3
appname1=InterWebPPC
upstream_g3=https://macintoshgarden.org/sites/macintoshgarden.org/files/apps/InterWebPPC-RR3-G3.zip
upstream_g4=https://macintoshgarden.org/sites/macintoshgarden.org/files/apps/InterWebPPC-RR3-G4.zip
upstream_g5=https://macintoshgarden.org/sites/macintoshgarden.org/files/apps/InterWebPPC-RR3-G5.zip

ublockxpi=uBlock0_1.16.4.30.firefox-legacy.xpi
upstream_ublock=https://github.com/gorhill/uBlock-for-firefox-legacy/releases/download/firefox-legacy-1.16.4.30/$ublockxpi

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

cd /opt/$pkgspec
mkdir -p bin
cd bin
for f in js xpcshell ; do
    ln -s ../$appname1.app/Contents/MacOS/$f .
done

mkdir -p /opt/$pkgspec/extras
cd /opt/$pkgspec/extras
echo -e "${COLOR_CYAN}Fetching${COLOR_NONE} $ublockxpi." >&2
url=$LEOPARDSH_MIRROR/dist/$ublockxpi
insecure_url=$(echo "$url" | sed 's|^https:|http:|')
size=$(curl --fail --silent --show-error --location --head $insecure_url \
    | grep -i '^content-length:' \
    | awk '{print $NF}' \
    | sed "s/$(printf '\r')//"
)
curl --fail --silent --show-error --location $url \
    | pv --force --size $size \
    > $ublockxpi

cd /opt/$pkgspec
cat > install-ublock.sh << EOF
#!/bin/bash
set -e
cd /opt/$pkgspec/$appname1.app/Contents/MacOS
./interwebppc file:///opt/$pkgspec/extras/$ublockxpi &
echo "Opening $ublockxpi with $appname1."
echo "Note: it may be several seconds before you see a browser window appear."
EOF
chmod +x install-ublock.sh

echo -e "${COLOR_YELLOW}Note:${COLOR_NONE} run /opt/$pkgspec/install-ublock.sh to install uBlock." >&2
