#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# Install racket on OS X / PowerPC.

package=racket
version=6.0.1
upstream=https://download.racket-lang.org/installers/$version/racket-minimal-${version}-ppc-macosx.dmg

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

if test "$($pkgmgr --cpu)" = "g3" ; then
    echo "Sorry, $pkgspec does not run on G3 processors." >&2
    exit 1
fi

tarball=$pkgspec.tiger.g4.tar.gz
url=$mirror/dist/$tarball
echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /opt." >&2
$pkgmgr --unpack-tarball-check-md5 $url /opt
