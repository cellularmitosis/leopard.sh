#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# Install openjdk on OS X / PowerPC.

# See https://web.archive.org/web/20150517050519/http://www.intricatesoftware.com/OpenJDK/macppc/
# See https://macintoshgarden.org/apps/openjdk7-ppc
# See https://macintoshgarden.org/forum/advancing-java-tiger-leopard

package=openjdk7
version=20120314
upstream=https://web.archive.org/web/20150822121344/http://www.intricatesoftware.com/OpenJDK/macppc/openjdk7u2-macppc-fcs-2012-03-14.tar.bz2
description="Open source implementation of the Java programming language"

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

tarball=$pkgspec.leopard.tar.gz
url=$mirror/dist/$tarball
echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /opt." >&2
$pkgmgr --unpack-tarball-check-md5 $url /opt

ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
