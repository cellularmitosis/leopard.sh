#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# Install InterWebPPC.app on OS X / PowerPC.

package=interwebppc.app
version=rr4
ucversion=RR4
appname1=InterWebPPC
upstream_g3=https://github.com/wicknix/InterWebPPC/releases/download/RR4/InterWebPPC-RR4.zip

ublock_xpi=uBlock0_1.16.4.30.firefox-legacy.xpi
upstream_ublock=https://github.com/gorhill/uBlock-for-firefox-legacy/releases/download/firefox-legacy-1.16.4.30/$ublock_xpi

noscript_xpi=noscript-5.1.9.xpi
upstream_noscript=https://noscript.net/download/releases/$noscript_xpi

greasemonkey_xpi=greasemonkey-3.11-fx.xpi
upstream_greasemonkey=https://web.archive.org/web/20171018071605/https://addons.cdn.mozilla.net/user-media/addons/_attachments/748/greasemonkey-3.11-fx.xpi?filehash=sha256%3A028aae4a9db333bca9958324b92ce2020159a133985223f702be432a30a432c7

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

# Note: RR4 is a single build for all architectures.
tarball=$pkgspec.g3.tar.gz
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
cd /opt/$pkgspec

for xpi_pair in "ublock $ublock_xpi" "noscript $noscript_xpi" "greasemonkey $greasemonkey_xpi" ; do
xpi_name=$(echo $xpi_pair | awk '{print $1}')
xpi=$(echo $xpi_pair | awk '{print $2}')

echo -e "${COLOR_CYAN}Fetching${COLOR_NONE} $xpi." >&2
url=$LEOPARDSH_MIRROR/dist/$xpi
insecure_url=$(echo "$url" | sed 's|^https:|http:|')
size=$(curl --fail --silent --show-error --location --head $insecure_url \
    | grep -i '^content-length:' \
    | awk '{print $NF}' \
    | sed "s/$(printf '\r')//"
)
curl --fail --silent --show-error --location $url \
    | pv --force --size $size \
    > extras/$xpi

cat > install-${xpi_name}.sh << EOF
#!/bin/bash
set -e
cd /opt/$pkgspec/$appname1.app/Contents/MacOS
./interwebppc file:///opt/$pkgspec/extras/$xpi &
echo "Opening $xpi with $appname1."
echo "Note: it may be several seconds before you see a browser window appear."
EOF
chmod +x install-${xpi_name}.sh

done

echo -e "${COLOR_YELLOW}Note:${COLOR_NONE} run /opt/$pkgspec/install-ublock.sh to install uBlock." >&2
echo -e "${COLOR_YELLOW}Note:${COLOR_NONE} run /opt/$pkgspec/install-noscript.sh to install NoScript." >&2
echo -e "${COLOR_YELLOW}Note:${COLOR_NONE} run /opt/$pkgspec/install-greasemonkey.sh to install Greasemonkey." >&2
echo "See also https://forums.macrumors.com/threads/userscripts-to-fix-tenfourfox-iwppc-web-compatibility.2394015/" >&2
