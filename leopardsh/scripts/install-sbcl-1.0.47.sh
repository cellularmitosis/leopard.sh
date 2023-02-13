#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# Install sbcl on OS X / PowerPC.

package=sbcl
version=1.0.47
upstream=https://master.dl.sourceforge.net/project/$project/$project/$version/$project-$version-source.tar.bz2
description="Steel Bank Common Lisp"

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

tarball=$pkgspec.tiger.g3.tar.gz
url=$mirror/dist/$tarball
echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /opt." >&2
$pkgmgr --unpack-tarball-check-md5 $url /opt

# sbcl will not run without sbcl.core being linked in the right location:
#   fatal error encountered in SBCL pid 14715:
#   can't find core file at /usr/local/lib/sbcl//sbcl.core
mkdir -p /usr/local/lib/sbcl
ln -sf /opt/$pkgspec/output/sbcl.core /usr/local/lib/sbcl/
