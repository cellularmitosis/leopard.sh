#!/bin/bash

# leopard.sh: package manager for PowerPC Macs running OS X Leopard (10.5).

set -e

# Note: for offline use, export e.g. LEOPARDSH_MIRROR=file:///Users/foo/leopardsh
# before calling leopard.sh.
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}
export LEOPARDSH_MIRROR

COLOR_GREEN="\\\e[32;1m"
COLOR_YELLOW="\\\e[33;1m"
COLOR_NONE="\\\e[0m"

osversion=$(sw_vers -productVersion | awk '{print $NF}')
if ! echo $osversion | grep -q '10\.5'; then
    echo "Sorry, this script was written for OS X Leopard :(" >&2
    exit 1
fi

set -o pipefail

cpu_id=$(sysctl hw.cpusubtype | awk '{print $NF}')
if test "$cpu_id" = "9" ; then
    cpu_name=g3
    cpu_num=750
elif test "$cpu_id" = "10" ; then
    cpu_name=g4
    cpu_num=7400
elif test "$cpu_id" = "11" ; then
    cpu_name=g4e
    cpu_num=7450
elif test "$cpu_id" = "100" ; then
    cpu_name=g5
    cpu_num=970
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
    if test "$cpu_name" = "g5" ; then
        flags="$flags -m32"
    fi
    shift 1
fi

if test "$1" = "-mcpu" ; then
    flagmode=1
    flags="$flags -mcpu=$cpu_num"
    shift 1
fi

if test "$1" = "-O" ; then
    flagmode=1
    if test "$cpu_name" = "g3" ; then
        flags="$flags -Os"
    elif test "$cpu_name" = "g4" ; then
        flags="$flags -Os"
    elif test "$cpu_name" = "g4e" ; then
        flags="$flags -O2"
    elif test "$cpu_name" = "g5" ; then
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
    echo $cpu_name
    exit 0
fi

if test "$1" = "--os.cpu" ; then
    echo leopard.$cpu_name
    exit 0
fi

# unlink:

if test "$1" = "--unlink" ; then
    shift 1
    if test -z "$1" ; then
        echo "Error: unlink which package?" >&2
        echo "e.g. leopard.sh --unlink foo-1.0" >&2
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
    curl -sSfLOk $LEOPARDSH_MIRROR/scripts/install-portable-curl.sh
    chmod +x install-portable-curl.sh
    ./install-portable-curl.sh
fi

opt_config_cache=/opt/leopard.sh/share/leopard.sh/config.cache
mkdir -p $opt_config_cache
if ! test -e $opt_config_cache/leopard.cache ; then
    cd $opt_config_cache
    curl -sSfLOk $LEOPARDSH_MIRROR/config.cache/leopard.cache
fi

if test "$1" = "--setup" ; then
    exit 0
fi

# arch check:

if test "$1" = "--arch-check" ; then
    shift 1
    if test -z "$1" ; then
        echo "Error: arch-check which package?" >&2
        echo "e.g. leopard.sh --arch-check foo-1.0" >&2
        exit 1
    fi
    pkgspec="$1"
    ppc64="$2"
    cd /opt/$pkgspec
    for d in bin sbin lib ; do
        if test -e /opt/$pkgspec/$d && test -n "$(ls /opt/$pkgspec/$d/)" ; then
            for f in $d/* ; do
                if test -f $f -a ! -L $f ; then
                    if test -z "$did_print_header" ; then
                        echo -e "\nArchitecture check: /opt/$pkgspec\n"
                        did_print_header=1
                    fi
                    file $f | sed 's/^/  /'
                    if test -n "$ppc64" ; then
                        echo -e "$(lipo -info $f 2>/dev/null \
                            | sed 's/^/    /' \
                            | sed "s/ ppc64/ ${COLOR_GREEN}ppc64${COLOR_NONE}/g" \
                            | sed "s/ ppc750/ ${COLOR_YELLOW}ppc750${COLOR_NONE}/g" \
                            | sed "s/ ppc7400/ ${COLOR_YELLOW}ppc7400${COLOR_NONE}/g" \
                            | sed "s/ ppc7450/ ${COLOR_YELLOW}ppc7450${COLOR_NONE}/g" \
                            | sed "s/ ppc970/ ${COLOR_YELLOW}ppc970${COLOR_NONE}/g" \
                            | sed "s/ ppc/ ${COLOR_YELLOW}ppc${COLOR_NONE}/g" \
                            || true
                        )"
                    else
                        echo -e "$(lipo -info $f 2>/dev/null \
                            | sed 's/^/    /' \
                            | sed "s/ ppc${cpu_num}/ ${COLOR_GREEN}ppc${cpu_num}${COLOR_NONE}/g" \
                            | sed "s/ ppc64/ ${COLOR_YELLOW}ppc64${COLOR_NONE}/g" \
                            | sed "s/ ppc750/ ${COLOR_YELLOW}ppc750${COLOR_NONE}/g" \
                            | sed "s/ ppc7400/ ${COLOR_YELLOW}ppc7400${COLOR_NONE}/g" \
                            | sed "s/ ppc7450/ ${COLOR_YELLOW}ppc7450${COLOR_NONE}/g" \
                            | sed "s/ ppc970/ ${COLOR_YELLOW}ppc970${COLOR_NONE}/g" \
                            | sed "s/ ppc/ ${COLOR_GREEN}ppc${COLOR_NONE}/g" \
                            || true
                        )"
                    fi
                    echo
                fi
            done
        fi
    done
    exit 0
fi

# linker check:

if test "$1" = "--linker-check" ; then
    shift 1
    if test -z "$1" ; then
        echo "Error: linker-check which package?" >&2
        echo "e.g. leopard.sh --linker-check foo-1.0" >&2
        exit 1
    fi
    pkgspec="$1"
    cd /opt/$pkgspec
    for d in bin sbin lib ; do
        if test -e /opt/$pkgspec/$d && test -n "$(ls /opt/$pkgspec/$d/)" ; then
            for f in $d/* ; do
                if test -f $f -a ! -L $f ; then
                    if test -z "$did_print_header" ; then
                        echo -e "\nLinker check: /opt/$pkgspec\n"
                        did_print_header=1
                    fi
                    echo -e "$(otool -L $f \
                        | sed 's/^/    /' \
                        | sed "s|/usr/|/${COLOR_YELLOW}usr${COLOR_NONE}/|g" \
                        | sed "s|/opt/|/${COLOR_GREEN}opt${COLOR_NONE}/|g" \
                    )"
                    echo
                fi
            done
        fi
    done
    exit 0
fi

# list:

if test -z "$1" ; then
    echo "Available packages:" >&2
    cd /tmp
    /opt/portable-curl/bin/curl -sSfLO $LEOPARDSH_MIRROR/packages.txt
    if test -n "$is_g5" ; then
        /opt/portable-curl/bin/curl -sSfLO $LEOPARDSH_MIRROR/packages.ppc64.txt
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

if ! which -s /usr/bin/gcc ; then
    echo "Error: please install Xcode." >&2
    echo "See https://macintoshgarden.org/sites/macintoshgarden.org/files/apps/xcode314_2809_developerdvd.dmg" >&2
    exit 1
fi

pkgspec="$1"
echo "Installing $pkgspec" >&2
echo -n -e "\033]0;leopard.sh $pkgspec (leopard.$cpu_name))\007"
script=install-$pkgspec.sh
cd /tmp
/opt/portable-curl/bin/curl -sSfLO $LEOPARDSH_MIRROR/scripts/$script
chmod +x $script
/usr/bin/time nice ./$script 2>&1 | tee /tmp/$script.log

if ! test -e /opt/$pkgspec/share/leopard.sh/$pkgspec/$script.log.gz ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip /tmp/$script.log
    mv /tmp/$script.log.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
