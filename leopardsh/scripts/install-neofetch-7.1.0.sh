#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# Install neofetch on OS X / PowerPC.

package=neofetch
version=7.1.0
upstream=https://github.com/dylanaraps/$package/archive/refs/tags/$version.tar.gz

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

echo -n -e "\033]0;$pkgmgr $pkgspec ($($pkgmgr --cpu))\007"

tarball=$pkgspec.tar.gz
url=$mirror/dist/$tarball
echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /opt." >&2
$pkgmgr --unpack-tarball-check-md5 $url /opt

# Tiger's stock bash is too old to run neofetch.
if test "${osversion:0:4}" = "10.4" ; then
    # thanks to https://stackoverflow.com/a/549261
    perl -i -pe 's|.*|#!/opt/tigersh-deps-0.1/bin/bash| if 1..1' /opt/$pkgspec/bin/neofetch
fi
