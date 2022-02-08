#!/bin/bash

# tiger.sh: build/install software on PowerPC Macs running OS X Tiger (10.4).

set -e

# Note: for offline use, export e.g. TIGERSH_MIRROR=file:///Users/foo/tigersh
# before calling tiger.sh.
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}
export TIGERSH_MIRROR

osversion=$(sw_vers -productVersion | awk '{print $NF}')
if ! echo $osversion | grep -q '10\.4' ; then
    echo "Sorry, this script was written for OS X Tiger :(" >&2
    exit 1
fi

cpu=$(sysctl hw.cpusubtype | awk '{print $NF}')
if test "$cpu" = "9" ; then
    is_g3=1
elif test "$cpu" = "10" ; then
    is_g4=1
elif test "$cpu" = "11" ; then
    is_g4e=1
elif test "$cpu" = "100" ; then
    is_g5=1
else
    echo "Error: unsupported CPU type." >&2
    exit 1
fi

# make flag generation:

if test "$1" = "-j" ; then
    j=$(sysctl hw.logicalcpu | awk '{print $NF}')
    echo "-j$j"
    exit 0
fi

# gcc flags generation:

if test "$1" = "-m32" ; then
    # print -m32, but only if on a G5.
    flagmode=1
    if test -n "$is_g5" ; then
        flags="$flags -m32"
    fi
    shift 1
fi

if test "$1" = "-mcpu" ; then
    flagmode=1
    if test -n "$is_g3" ; then
        flags="$flags -mcpu=750"
    elif test -n "$is_g4" ; then
        flags="$flags -mcpu=7400"
    elif test -n "$is_g4e" ; then
        flags="$flags -mcpu=7450"
    elif test -n "$is_g5" ; then
        flags="$flags -mcpu=970"
    fi
    shift 1
fi

if test "$1" = "-O" ; then
    flagmode=1
    if test -n "$is_g3" ; then
        flags="$flags -Os"
    elif test -n "$is_g4" ; then
        flags="$flags -Os"
    elif test -n "$is_g4e" ; then
        flags="$flags -O2"
    elif test -n "$is_g5" ; then
        flags="$flags -O2"
    fi
    shift 1
fi

if test -n "$flagmode" ; then
    flags="$(echo $flags | sed 's/^ //')"
    echo "$flags"
    exit 0
fi

# sysctl queries:

if test "$1" = "--cpu" ; then
    if test -n "$is_g3" ; then
        echo g3
    elif test -n "$is_g4" ; then
        echo g4
    elif test -n "$is_g4e" ; then
        echo g4e
    elif test -n "$is_g5" ; then
        echo g5
    fi
    exit 0
fi

if test "$1" = "--os.cpu" ; then
    if test -n "$is_g3" ; then
        echo tiger.g3
    elif test -n "$is_g4" ; then
        echo tiger.g4
    elif test -n "$is_g4e" ; then
        echo tiger.g4e
    elif test -n "$is_g5" ; then
        echo tiger.g5
    fi
    exit 0
fi

# unlink:

if test "$1" = "--unlink" ; then
    shift 1
    if test -z "$1" ; then
        echo "Error: unlink which package?" >&2
        echo "e.g. tiger.sh --unlink foo-1.0" >&2
        exit 1
    fi
    pkgspec="$1"
    # deletes any symlinks in /usr/local/* which point to /opt/foo-1.0/*.
    # what a pain in the ass!
    cd "/opt/$pkgspec"
    find . -mindepth 1 \( -type f -or -type l \) -exec \
        bash -e -c \
            "if test -L \"/usr/local/{}\" \
                && test \"\$(readlink \"/usr/local/{}\")\" = \"/opt/$pkgspec/\$(echo {} | cut -c3-)\" ; \
            then \
                rm -v \"/usr/local/{}\"
            fi" \
    \;
    exit 0
fi

# setup:

if ! type -a /usr/bin/gcc >/dev/null 2>&1 ; then
    echo "Error: please install Xcode." >&2
    echo "See https://macintoshgarden.org/sites/macintoshgarden.org/files/apps/xcode25_8m2558_developerdvd.dmg" >&2
    exit 1
fi

if ! test -e /opt ; then
    echo "Creating /opt." >&2
    sudo mkdir /opt
    sudo chgrp admin /opt
    sudo chmod g+w /opt
fi

if ! mktemp /opt/write-check.XXX >/dev/null ; then
    echo "Notice: can't write to /opt." >&2
    echo "Running 'sudo chgrp admin /opt && sudo chmod g+w /opt'." >&2
    sudo chgrp admin /opt
    sudo chmod g+w /opt
else
    rm -f /opt/write-check.*
fi

if ! mktemp /opt/write-check.XXX >/dev/null ; then
    echo "Error: can't write to /opt." >&2
    echo "Check that you are in the 'admin' group (run 'groups')." >&2
    exit 1
else
    rm -f /opt/write-check.*
fi

for d in /usr/local /usr/local/bin /usr/local/sbin ; do
    if ! test -e $d ; then
        echo "Creating $d." >&2
        sudo mkdir -p $d
        sudo chgrp admin $d
        sudo chmod g+w $d
    fi
done

mkdir -p ~/Downloads

if ! test -e /opt/portable-curl ; then
    echo "Installing curl with SSL support." >&2
    cd /tmp
    curl -sSfLOk $TIGERSH_MIRROR/scripts/install-portable-curl.sh
    chmod +x install-portable-curl.sh
    ./install-portable-curl.sh
fi

opt_config_cache=/opt/tiger.sh/share/tiger.sh/config.cache
mkdir -p $opt_config_cache
if ! test -e $opt_config_cache/tiger.cache ; then
    cd $opt_config_cache
    curl -sSfLOk $TIGERSH_MIRROR/config.cache/tiger.cache
fi

if test "$1" = "--setup" ; then
    exit 0
fi

# list:

if test -z "$1" ; then
    echo "Available packages:" >&2
    cd /tmp
    /opt/portable-curl/bin/curl -sSfLO $TIGERSH_MIRROR/packages.txt
    if test -n "$is_g5" ; then
        /opt/portable-curl/bin/curl -sSfLO $TIGERSH_MIRROR/packages.ppc64.txt
        cat packages.txt packages.ppc64.txt | sort
    else
        cat packages.txt
    fi
    exit 0
fi

# install:

if test -n "$1" -a -e "/opt/$1" ; then
    echo "$1 is already installed." >&2
    exit 0
fi

# Thanks to https://trac.macports.org/ticket/16286
export MACOSX_DEPLOYMENT_TARGET=10.4

pkgspec="$1"
echo "Installing $pkgspec" >&2
echo -n -e "\033]0;tiger.sh $pkgspec ($(hostname -s))\007"
script=install-$pkgspec.sh
cd /tmp
/opt/portable-curl/bin/curl -sSfLO $TIGERSH_MIRROR/scripts/$script
chmod +x $script

# unfortunately, tiger's bash doesn't have pipefail.
# thanks to https://stackoverflow.com/a/1221844
fifo=/tmp/.tiger.sh.$script.fifo
rm -f $fifo
mkfifo $fifo
tee /tmp/$script.log < $fifo &
/usr/bin/time nice ./$script > $fifo 2>&1

if ! test -e /opt/$pkgspec/share/tiger.sh/$pkgspec/$script.log.gz ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip /tmp/$script.log
    mv /tmp/$script.log.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi

rm -f $fifo