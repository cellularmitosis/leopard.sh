#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/install-app.sh v1

# Install Petite Chez Scheme on OS X / PowerPC.

package=petite-chezscheme
version=7.4
upstream=https://www.scheme.com/csv7.4/pcsv7.4-ppcosx.tar.gz

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

# petite will not run without petite.boot being linked in the right location:
#  cannot find compatible petite.boot in search path
#    "/Users/macuser/lib/csv%v/%m:/usr/lib/csv%v/%m:/usr/local/lib/csv%v/%m"
mkdir -p /usr/local/lib/csv7.4
ln -sf /opt/$pkgspec/lib/csv7.4/* /usr/local/lib/csv7.4/
