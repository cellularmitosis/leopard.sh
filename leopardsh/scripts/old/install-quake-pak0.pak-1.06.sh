#!/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install Quake shareware data on OS X Tiger / PowerPC.

package=quake-pak0.pak
version=1.06

set -e -x
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

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

srcmirror=https://www.gamers.org/pub/idgames/idstuff/quake
zip=quake106.zip

if ! test -e ~/Downloads/$zip ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$zip
fi

test "$(md5 ~/Downloads/$zip | awk '{print $NF}')" = 8cee4d03ee092909fdb6a4f84f0c1357

mkdir -p /opt/$pkgspec
cd /opt/$pkgspec

unzip -q ~/Downloads/$zip

lha xq resource.1 id1/pak0.pak

# md5 hash from https://quakewiki.org/w/index.php?title=pak0.pak
test "$(md5 id1/pak0.pak | awk '{print $NF}')" = 5906e5998fc3d896ddaf5e6a62e03abb

mkdir -p ~/.quake/id1
ln -sf /opt/$pkgspec/id1/pak0.pak ~/.quake/id1/
