#!/opt/tigersh-deps-0.1/bin/bash

# Install Quake II shareware data on OS X Tiger / PowerPC.

package=quake2-pak0.pak
version=3.14

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

srcmirror=ftp://ftp.idsoftware.com/idstuff/quake2  # offline?
srcmirror=https://web.archive.org/web/20151201225632/ftp://ftp.idsoftware.com/idstuff/quake2
srcmirror=https://ftp.gwdg.de/pub/misc/ftp.idsoftware.com/idstuff/quake2
srcmirror=ftp://ftp.gamers.org/pub/idgames/idstuff/quake2
srcmirror=https://leopard.sh/dist/orig
zip=q2-314-demo-x86.exe

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
mkdir -p baseq2
size=$(unzip -l ~/Downloads/$zip Install/Data/baseq2/pak0.pak \
    | tail -n1 \
    | awk '{print $1}'
)
unzip -p -q ~/Downloads/$zip Install/Data/baseq2/pak0.pak \
    | pv --force --size $size \
    > baseq2/pak0.pak

test "$(md5 baseq2/pak0.pak | awk '{print $NF}')" = 27d77240466ec4f3253256832b54db8a

mkdir -p ~/.quake2/baseq2
if ! test -e ~/.quake2/baseq2/pak0.pak ; then
    ln -sf /opt/$pkgspec/baseq2/pak0.pak ~/.quake2/baseq2/
fi
