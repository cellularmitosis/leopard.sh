#!/bin/bash

# leopard.sh: build/install software for OS X Leopard / PowerPC.

set -e -o pipefail

# Note: to use a local checkout, export LEOPARDSH_MIRROR=file:///Users/foo/leopard.sh
# before calling leopard.sh.
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}
export LEOPARDSH_MIRROR

osversion=$(sw_vers -productVersion | awk '{print $NF}')
if ! echo $osversion | grep -q '10\.5'; then
    echo "Sorry, this script was written for OS X Leopard :(" >&2
    exit 1
fi

if test "$1" = "-m64"; then
    flagmode=1
    cpu=$(sysctl hw.cpusubtype | awk '{print $NF}')
    if test "$cpu" = "100"; then
        flags="$flags -m64"
    fi
    shift 1
fi

if test "$1" = "-mcpu"; then
    flagmode=1
    cpu=$(sysctl hw.cpusubtype | awk '{print $NF}')
    if test "$cpu" = "9"; then
        flags="$flags -mcpu=750"
    elif test "$cpu" = "10"; then
        flags="$flags -mcpu=7400"
    elif test "$cpu" = "11"; then
        flags="$flags -mcpu=7450"
    elif test "$cpu" = "100"; then
        flags="$flags -mcpu=970"
    else
        echo "Error: unsupported CPU type." >&2
        exit 1
    fi
    shift 1
fi

if test "$1" = "-O"; then
    flagmode=1
    cpu=$(sysctl hw.cpusubtype | awk '{print $NF}')
    if test "$cpu" = "9"; then
        flags="$flags -Os"
    elif test "$cpu" = "10"; then
        flags="$flags -Os"
    elif test "$cpu" = "11"; then
        flags="$flags -O2"
    elif test "$cpu" = "100"; then
        flags="$flags -O2"
    else
        echo "Error: unsupported CPU type." >&2
        exit 1
    fi
    shift 1
fi

if test -n "$flagmode"; then
    flags="$(echo $flags | sed 's/^ //')"
    echo "$flags"
    exit 0
fi

if test "$1" = "--cpu"; then
    cpu=$(sysctl hw.cpusubtype | awk '{print $NF}')
    if test "$cpu" = "9"; then
        echo g3
    elif test "$cpu" = "10"; then
        echo g4
    elif test "$cpu" = "11"; then
        echo g4e
    elif test "$cpu" = "100"; then
        echo g5
    else
        echo "Error: unsupported CPU type." >&2
        exit 1
    fi
    exit 0
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

if test "$1" = "--unlink"; then
    shift 1
    if test -z "$1"; then
        echo "Error: unlink which package?" >&2
        echo "e.g. leopard.sh --unlink foo-1.0" >&2
        exit 1
    fi
    pkg="$1"
    # deletes any symlinks in /usr/local/* which point to /opt/foo-1.0/*.
    # what a pain in the ass!
    cd "/opt/$pkg"
    find . -mindepth 1 \( -type f -or -type l \) -exec \
        bash -e -c \
            "if test -L \"/usr/local/{}\" \
                && test \"\$(readlink \"/usr/local/{}\")\" = \"/opt/$pkg/\$(echo {} | cut -c3-)\" ; \
            then \
                rm -v \"/usr/local/{}\"
            fi" \
    \;
    exit 0
fi

if test -n "$1" -a -e "/opt/$1"; then
    # already installed.
    exit 0
fi

if ! which -s /usr/bin/gcc ; then
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
    curl -sSfLOk $LEOPARDSH_MIRROR/scripts/install-portable-curl.sh
    chmod +x install-portable-curl.sh
    ./install-portable-curl.sh
fi

if test -z "$1"; then
    echo "Available packages:" >&2
    /opt/portable-curl/bin/curl -sSfL $LEOPARDSH_MIRROR/packages.txt
    exit 0
fi

pkg="$1"
echo "Installing $pkg" >&2
echo -n -e "\033]0;Installing $pkg\007"
script=install-$pkg.sh
cd /tmp
/opt/portable-curl/bin/curl -sSfLO $LEOPARDSH_MIRROR/scripts/$script
chmod +x $script
/usr/bin/time nice ./$script 2>&1 | tee /tmp/$script.log

mkdir -p /opt/$pkg/share/leopard.sh
gzip /tmp/$script.log
mv /tmp/$script.log.gz /opt/$pkg/share/leopard.sh/
