#!/bin/bash

# leopard.sh: build/install software for OS X Leopard / PowerPC.

set -e -o pipefail

LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}
export LEOPARDSH_MIRROR

osversion=$(sw_vers -productVersion | awk '{print $NF}')
if ! echo $osversion | grep -q '10\.5'; then
    echo "Sorry, this script was written for OS X Leopard :(" >&2
    exit 1
fi

if test "$1" = "--os.cpu"; then
    cpu=$(sysctl hw.cpusubtype | awk '{print $NF}')
    if test "$cpu" = "9"; then
        echo leopard.g3
    elif test "$cpu" = "10"; then
        echo leopard.g4
    elif test "$cpu" = "11"; then
        echo leopard.g4e
    elif test "$cpu" = "100"; then
        echo leopard.g5
    else
        echo "Error: unsupported CPU type." >&2
        exit 1
    fi
    exit 0
fi

if test -n "$1" -a -e /opt/$1; then
    exit 0
fi

if ! which /usr/bin/gcc >/dev/null 2>&1; then
    echo "Error: please install Xcode." >&2
    echo "See https://macintoshgarden.org/sites/macintoshgarden.org/files/apps/xcode314_2809_developerdvd.dmg" >&2
    exit 1
fi

if ! test -e /opt; then
    echo "Creating /opt." >&2
    sudo mkdir /opt
    sudo chgrp admin /opt
    sudo chmod g+w /opt
fi

if ! mktemp /opt/write-check.XXX >/dev/null; then
    echo "Error: can't write to /opt." >&2
    echo "Try 'sudo chmod g+w /opt'." >&2
    echo "Also, ensure you are in the 'admin' group." >&2
    exit 1
else
    rm -f /opt/write-check.*
fi

for d in /usr/local /usr/local/bin /usr/local/sbin; do
    if ! test -e $d; then
        echo "Creating $d." >&2
        sudo mkdir -p $d
        sudo chgrp admin $d
        sudo chmod g+w $d
    fi
done

if ! test -e /opt/portable-curl; then
    echo "Installing curl with SSL support." >&2
    cd /tmp
    curl -sSfLOk $LEOPARDSH_MIRROR/install-portable-curl.sh
    chmod +x install-portable-curl.sh
    ./install-portable-curl.sh
fi

if test -z "$1"; then
    echo "Available packages:" >&2
    /opt/portable-curl/bin/curl -sSfL $LEOPARDSH_MIRROR/packages.txt
    exit 0
fi

echo "Installing $1" >&2
echo -n -e "\033]0;Installing $1\007"
script=install-$1.sh
cd /tmp
/opt/portable-curl/bin/curl -sSfLO $LEOPARDSH_MIRROR/$script
chmod +x $script
nice ./$script | tee /tmp/$script.log
