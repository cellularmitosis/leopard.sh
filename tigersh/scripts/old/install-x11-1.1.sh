#!/opt/tigersh-deps-0.1/bin/bash

# Install X11 1.1.

package=x11
version=1.1

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -e /usr/X11R6/bin/Xquartz ; then
    echo "x11-1.1 is already installed." >&2
    exit 0
fi

cd /tmp
curl X11User.pkg.tar.gz | gunzip | tar x
open X11user.pkg
