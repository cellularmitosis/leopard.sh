#!/opt/tigersh-deps-0.1/bin/bash

# Install jpm on OS X / PowerPC.

package=jpm
version=20220911
janet_version=1.25.1
upstream=https://github.com/janet-lang/jpm/archive/refs/heads/master.tar.gz

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

if ! test -e /opt/janet-$janet_version ; then
    $pkgmgr janet-$janet_version
fi

if ! type -a git >/dev/null 2>&1 ; then
    $pkgmgr git-2.35.1
fi

echo -n -e "\033]0;$pkgmgr $pkgspec ($($pkgmgr --cpu))\007"

tarball=$pkgspec.tar.gz
url=$mirror/dist/$tarball

echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /opt." >&2
rm -rf /tmp/$pkgspec
$pkgmgr --unpack-tarball-check-md5 $url /tmp

echo -e "${COLOR_CYAN}Setting up${COLOR_NONE} ${COLOR_YELLOW}jpm${COLOR_NONE}." >&2
cd /tmp/$pkgspec
PREFIX=/opt/janet-$janet_version janet bootstrap.janet
ln -sfv /opt/janet-$janet_version/bin/jpm /usr/local/bin/jpm
jpm update-pkgs
