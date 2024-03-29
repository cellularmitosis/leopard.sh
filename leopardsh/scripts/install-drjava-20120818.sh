#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# Install drjava on OS X / PowerPC.

# See http://www.drjava.org/download.shtml

package=drjava
version=20120818
upstream=https://cytranet.dl.sourceforge.net/project/drjava/1.%20DrJava%20Stable%20Releases/drjava-stable-20120818-r5686/drjava-stable-20120818-r5686.jar
description="Java IDE"

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

dep=openjdk7-20120314
if ! test -e /opt/$dep ; then
    $pkgmgr $dep
fi

echo -n -e "\033]0;$pkgmgr $pkgspec ($($pkgmgr --cpu))\007"

tarball=$pkgspec.tar.gz
url=$mirror/dist/$tarball
echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /opt." >&2
$pkgmgr --unpack-tarball-check-md5 $url /opt
