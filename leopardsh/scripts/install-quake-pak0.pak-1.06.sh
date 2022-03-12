#!/opt/tigersh-deps-0.1/bin/bash

# Install Quake shareware data on OS X Tiger / PowerPC.

package=quake-pak0.pak
version=1.06

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

if ! test -e /opt/lhasa-0.3.1 ; then
    $pkgmgr lhasa-0.3.1
fi

srcmirror=ftp://ftp.idsoftware.com/idstuff/quake  # offline?
srcmirror=https://web.archive.org/web/20151201225632/ftp://ftp.idsoftware.com/idstuff/quake
srcmirror=https://ftp.gwdg.de/pub/misc/ftp.idsoftware.com/idstuff/quake
srcmirror=ftp://ftp.gamers.org/pub/idgames/idstuff/quake
zip=quake106.zip

echo -n -e "\033]0;$pkgmgr $pkgspec ($($pkgmgr --cpu))\007"

if ! test -e ~/Downloads/$zip ; then
    echo -e "${COLOR_CYAN}Fetching${COLOR_NONE} $zip." >&2
    url=$srcmirror/$zip
    size=$(curl --fail --silent --show-error --head $url \
        | grep -i '^content-length:' \
        | awk '{print $NF}' \
        | sed "s/$(printf '\r')//"
    )
    curl --fail --silent --show-error $url \
        | pv --force --size $size \
        > ~/Downloads/$zip
fi

echo -e "${COLOR_CYAN}Extracting${COLOR_NONE} pak0.pak." >&2
cd /opt/$pkgspec
size=$(stat -f '%z' ~/Downloads/$zip)
unzip -p -q ~/Downloads/$zip resource.1 \
    | pv --force --size $size \
    | lha -xq - id1/pak0.pak

# md5 hash from https://quakewiki.org/w/index.php?title=pak0.pak
test "$(md5 id1/pak0.pak | awk '{print $NF}')" = 5906e5998fc3d896ddaf5e6a62e03abb

mkdir -p ~/.quake/id1
if ! test -e ~/.quake/id1/pak0.pak ; then
    ln -sf /opt/$pkgspec/id1/pak0.pak ~/.quake/id1/
fi
