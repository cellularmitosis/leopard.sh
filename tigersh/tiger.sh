#!/bin/bash

# tiger.sh: package manager for PowerPC Macs running OS X Tiger (10.4).
# see https://github.com/cellularmitosis/leopard.sh

set -e

# vars:

# Note: for offline use or to run you own local fork, export e.g.
#   TIGERSH_MIRROR=file:///Users/foo/github/cellularmitosis/leopard.sh
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}
export TIGERSH_MIRROR

# no alarms and no surprises, please.
export PATH="/opt/tigersh-deps-0.1/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# FIXME this doesn't work if tiger.sh is called bare.
script_path=$(cd "$(dirname "$0")" && pwd)

COLOR_GREEN="\\\e[32;1m"
COLOR_YELLOW="\\\e[33;1m"
COLOR_CYAN="\\\e[36;1m"
COLOR_NONE="\\\e[0m"


# process the command line args:

needs_setup_check=1

if test "$1" = "--unlink" ; then
    op=unlink
elif test "$1" = "-j" ; then
    op=makeflags
elif test "$1" = "-m32" -o "$1" = "-mcpu" -o "$1" = "-O" ; then
    op=gccflags
elif test "$1" = "--cpu" -o "$1" = "--os.cpu" ; then
    op=platform-info
elif test "$1" = "--arch-check" ; then
    op=arch-check
elif test "$1" = "--linker-check" ; then
    op=linker-check
elif test "$1" = "--url-exists" ; then
    op=url-exists
elif test "$1" = "--install-binpkg" ; then
    op=installbinpkg
elif test "$1" = "--unpack-dist" ; then
    op=unpack-dist
elif test "$1" = "--unpack-tarball-check-md5" ; then
    op=unpack-tarball-check-md5
elif test "$1" = "--setup" ; then
    op=setup
elif test "$1" = "--list" ; then
    op=list
elif test -n "$1" ; then
    op=install
else
    op=list
fi

if test "$op" = "list" \
-o "$op" = "install" \
-o "$op" = "gccflags" \
-o "$op" = "platform-info"; then
    needs_cpu_info=1
fi

if test -n "$TIGERSH_RECURSED" ; then
    unset needs_setup_check
fi

orig_pwd=$PWD

if ! test -e ~/.tigersh/checks ; then
    mkdir -p ~/.tigersh/checks
fi


# get the CPU type:

if test -n "$needs_cpu_info" ; then
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
fi


# setup:

if test -n "$needs_setup_check" ; then
    if ! test -e ~/.tigersh/checks/os-is-tiger ; then
        osversion=$(sw_vers -productVersion)
        if ! test "${osversion:0:4}" = "10.4" ; then
            echo "Sorry, this script was written for OS X Tiger :(" >&2
            exit 1
        else
            touch ~/.tigersh/checks/os-is-tiger
        fi
    fi

    if ! test -e ~/.tigersh/checks/user-in-admin-group ; then
        if ! dseditgroup -o checkmember -m $USER admin >/dev/null ; then
            echo "Adding your user to the admin group." >&2
            sudo dscl . append /Groups/admin GroupMembership $USER
            echo "Please open a new Terminal window for this change to take effect." >&2
            exit 1
        else
            touch ~/.tigersh/checks/user-in-admin-group
        fi
    fi

    # thanks to https://stackoverflow.com/a/61367055
    for pair in \
    "opt /opt" \
    "usr-local /usr/local" \
    "usr-local-bin /usr/local/bin" \
    "usr-local-sbin /usr/local/sbin" \
    "usr-local-share /usr/local/share" \
    "usr-local-share-man /usr/local/share/man" \
    ; do
        arr=($pair)
        stamp="can-write-in-${arr[0]}"
        d="${arr[1]}"

        if test -e ~/.tigersh/checks/$stamp ; then
            continue
        fi

        if ! test -e $d ; then
            echo "Creating $d." >&2
            sudo mkdir $d
            sudo chgrp admin $d
            sudo chmod g+w $d
        else
            if ! test "$(stat -f '%Sg' /opt)" = "admin" ; then
                echo "Changing group of $d to admin." >&2
                sudo chgrp admin $d
            fi
            if ! test "$(expr $(stat -f '%Sp' /opt) : '.....\(.\)')" = "w" ; then
                echo "Making $d group-writeable." >&2
                sudo chmod g+w $d
            fi
        fi

        if ! mktemp $d/write-check.XXX >/dev/null ; then
            echo "Error: can't write to $d." >&2
            exit 1
        else
            touch ~/.tigersh/checks/$stamp
            rm -f $d/write-check.*
        fi
    done

    if ! test -e ~/Downloads ; then
        mkdir -p ~/Downloads
    fi

    deps_pkgspec=tigersh-deps-0.1
    if test ! -e /opt/$deps_pkgspec \
    || test -e /opt/$deps_pkgspec/INCOMPLETE_INSTALLATION ; then
        echo "Installing tiger.sh dependencies (pv, curl w/SSL, otool w/ppc64 support)." >&2

        rm -rf /opt/$deps_pkgspec
        mkdir -p /opt/$deps_pkgspec
        touch /opt/$deps_pkgspec/INCOMPLETE_INSTALLATION

        cd /tmp

        binpkg=$deps_pkgspec.tiger.g3.tar.gz
        fifo=/tmp/$binpkg.fifo
        rm -f $fifo
        ( mkfifo $fifo \
            && cat $fifo | nice md5 > /tmp/$binpkg.localmd5_ \
            && mv /tmp/$binpkg.localmd5_ /tmp/$binpkg.localmd5
        ) &

        while ! test -e $fifo ; do sleep 0.1 ; done

        url=$TIGERSH_MIRROR/binpkgs/$binpkg
        # At this point we are still using /usr/bin/curl, so drop back to http.
        url=$(echo "$url" | sed 's|^https:|^http:|')
        size=$(curl --fail --silent --show-error --head --insecure $url \
            | grep -i '^content-length:' \
            | awk '{print $NF}' \
            | sed "s/$(printf '\r')//"
        )

        cd /opt
        nice curl --fail --silent --show-error --insecure $url \
            | tee $fifo \
            | nice gunzip \
            | nice tar x

        while ! test -e /tmp/$binpkg.localmd5 ; do sleep 0.1 ; done

        rm $fifo

        # Note: this qr code was generated via 'qrencode -t ANSI https://leopard.sh/md5'
        echo
        cat >&2 << EOF
[47m                                                            [0m
[47m                                                            [0m
[47m     [40m              [47m      [40m  [47m    [40m      [47m    [40m              [47m     [0m
[47m     [40m  [47m          [40m  [47m    [40m  [47m      [40m  [47m  [40m    [47m  [40m  [47m          [40m  [47m     [0m
[47m     [40m  [47m  [40m      [47m  [40m  [47m  [40m  [47m    [40m  [47m    [40m      [47m  [40m  [47m  [40m      [47m  [40m  [47m     [0m
[47m     [40m  [47m  [40m      [47m  [40m  [47m    [40m  [47m    [40m  [47m    [40m    [47m  [40m  [47m  [40m      [47m  [40m  [47m     [0m
[47m     [40m  [47m  [40m      [47m  [40m  [47m    [40m  [47m    [40m        [47m    [40m  [47m  [40m      [47m  [40m  [47m     [0m
[47m     [40m  [47m          [40m  [47m      [40m      [47m  [40m    [47m    [40m  [47m          [40m  [47m     [0m
[47m     [40m              [47m  [40m  [47m  [40m  [47m  [40m  [47m  [40m  [47m  [40m  [47m  [40m              [47m     [0m
[47m                     [40m  [47m    [40m  [47m  [40m    [47m  [40m  [47m                     [0m
[47m     [40m      [47m  [40m          [47m      [40m    [47m  [40m        [47m      [40m  [47m         [0m
[47m     [40m  [47m    [40m  [47m  [40m  [47m  [40m      [47m  [40m    [47m        [40m    [47m          [40m  [47m     [0m
[47m     [40m  [47m  [40m  [47m  [40m  [47m  [40m      [47m  [40m      [47m      [40m      [47m  [40m  [47m  [40m      [47m     [0m
[47m     [40m            [47m  [40m        [47m  [40m          [47m      [40m  [47m    [40m  [47m       [0m
[47m     [40m    [47m        [40m  [47m  [40m  [47m  [40m    [47m  [40m  [47m    [40m      [47m    [40m  [47m  [40m    [47m     [0m
[47m       [40m  [47m  [40m    [47m    [40m  [47m  [40m      [47m  [40m  [47m    [40m      [47m    [40m  [47m    [40m  [47m     [0m
[47m     [40m  [47m  [40m  [47m    [40m    [47m  [40m  [47m              [40m    [47m  [40m  [47m    [40m      [47m     [0m
[47m       [40m        [47m    [40m    [47m  [40m    [47m  [40m  [47m        [40m  [47m  [40m  [47m    [40m  [47m       [0m
[47m     [40m  [47m        [40m      [47m        [40m      [47m  [40m            [47m           [0m
[47m                     [40m  [47m  [40m          [47m  [40m  [47m      [40m    [47m  [40m    [47m     [0m
[47m     [40m              [47m  [40m  [47m    [40m    [47m    [40m    [47m  [40m  [47m  [40m    [47m  [40m    [47m     [0m
[47m     [40m  [47m          [40m  [47m  [40m  [47m  [40m  [47m  [40m      [47m  [40m  [47m      [40m    [47m  [40m    [47m     [0m
[47m     [40m  [47m  [40m      [47m  [40m  [47m  [40m  [47m    [40m  [47m    [40m  [47m  [40m            [47m  [40m    [47m     [0m
[47m     [40m  [47m  [40m      [47m  [40m  [47m      [40m    [47m              [40m        [47m         [0m
[47m     [40m  [47m  [40m      [47m  [40m  [47m  [40m  [47m        [40m  [47m    [40m    [47m    [40m  [47m      [40m  [47m     [0m
[47m     [40m  [47m          [40m  [47m  [40m  [47m    [40m  [47m      [40m      [47m    [40m    [47m  [40m  [47m       [0m
[47m     [40m              [47m  [40m  [47m  [40m  [47m  [40m  [47m    [40m    [47m  [40m    [47m      [40m    [47m     [0m
[47m                                                            [0m
[47m                                                            [0m
EOF
        echo >&2
        echo "OS X Tiger's support for SSL is too old to use, which means this script" >&2
        echo "can't verify the integrity of the dependencies which it just downloaded." >&2
        echo >&2
        echo "Please visit https://leopard.sh/md5 in a modern browser (or by scanning the" >&2
        echo "above QR code on your smartphone) and verify the following MD5 sums:" >&2
        echo >&2
        echo "The MD5 sum of $(basename "$0") is:" >&2
        echo >&2
        echo "    $(md5 -q "$script_path/$(basename "$0")")" >&2
        echo >&2
        echo "The MD5 sum of $binpkg is:" >&2
        echo >&2
        echo "    $(cat /tmp/$binpkg.localmd5)" >&2
        echo >&2

        read -p "Do the MD5 sums match? [Y/n]: " answer
        while true ; do
            if test "$answer" = "y" -o "$answer" = "Y" -o "$answer" = "" ; then
                break
            elif test "$answer" = "n" -o "$answer" = "N" ; then
                echo >&2
                echo "If the MD5 sums don't match, that means something is wrong." >&2
                echo >&2
                echo "Please google 'macrumors powerpc' and start a forum thread." >&2
                echo "The user 'cellularmitosis' will assist you." >&2
                echo >&2
                echo "Alternatively, if you are a github user, feel free to create an" >&2
                echo "issue at https://github.com/cellularmitosis/leopard.sh" >&2
                exit 1
            else
                read -p "Please type 'y', 'n' or hit ENTER (same as 'y') " answer
            fi
        done

        rm /opt/$deps_pkgspec/INCOMPLETE_INSTALLATION
    fi

    if ! test -e ~/.tigersh/checks/usr-local-bin-in-path ; then
        if ! echo $PATH | tr ':' '\n' | egrep '^/usr/local/bin/?$' >/dev/null ; then
            echo "Adding /usr/local/bin to your \$PATH." >&2
            for f in ~/.bashrc ~/.bash_profile ~/.profile ; do
                if test -e $f ; then
                    echo >> $f
                    echo "# Added by tiger.sh:" >> $f
                    echo "export PATH=\"/usr/local/bin:/usr/local/sbin:\$PATH\"" >> $f
                fi
            done
            echo "Please open a new Terminal window for this change to take effect." >&2
            exit 1
        else
            touch ~/.tigersh/checks/usr-local-bin-in-path
        fi
    fi

    opt_config_cache=/opt/tiger.sh/share/tiger.sh
    if ! test -e $opt_config_cache/tiger.cache ; then
        echo "Fetching configure cache." >&2
        mkdir -p $opt_config_cache
        cd $opt_config_cache
        curl --fail --silent --show-error --location --remote-name \
            $TIGERSH_MIRROR/tigersh/config.cache/tiger.cache
    fi
fi


# list:

if test "$op" = "list" ; then
    echo "Available packages:" >&2
    cd /tmp
    curl --fail --silent --show-error --location --remote-name \
        $TIGERSH_MIRROR/tigersh/packages.txt
    if test "$cpu_name" = "g5" ; then
        curl --fail --silent --show-error --location --remote-name \
            $TIGERSH_MIRROR/tigersh/packages.ppc64.txt
        cat packages.txt packages.ppc64.txt | sort
    else
        cat packages.txt
    fi
    rm -f packages.txt packages.ppc64.txt

    exit 0
fi


# install:

if test "$op" = "install" ; then
    pkgspec="$1"

    if test -e "/opt/$pkgspec" \
    && test ! -e "/opt/$pkgspec/INCOMPLETE_INSTALLATION" ; then
        echo "$pkgspec is already installed at /opt/$pkgspec" >&2
        exit 0
    fi

    rm -rf /opt/$pkgspec

    # Thanks to https://trac.macports.org/ticket/16286
    export MACOSX_DEPLOYMENT_TARGET=10.4

    pkgspec="$1"
    echo "Installing $pkgspec." >&2
    echo -n -e "\033]0;tiger.sh $pkgspec (tiger.$cpu_name)\007"
    mkdir -p /opt/$pkgspec
    touch /opt/$pkgspec/INCOMPLETE_INSTALLATION
    script=install-$pkgspec.sh
    cd /tmp
    echo "Fetching $script." >&2
    curl --fail --silent --show-error --location --remote-name \
        $TIGERSH_MIRROR/tigersh/scripts/$script
    chmod +x $script

    # unfortunately, tiger's bash doesn't have pipefail.
    # thanks to https://stackoverflow.com/a/1221844
    fifo=/tmp/.tiger.sh.$script.fifo
    rm -f $fifo
    mkfifo $fifo
    tee /tmp/$script.log < $fifo &
    TIGERSH_RECURSED=1 nice ./$script > $fifo 2>&1
    rm -f $fifo

    if find /opt/$pkgspec/bin -mindepth 1 2>/dev/null | grep -q . ; then
        ln -vsf /opt/$pkgspec/bin/* /usr/local/bin
    fi

    if find /opt/$pkgspec/sbin -mindepth 1 2>/dev/null | grep -q . ; then
        ln -vsf /opt/$pkgspec/sbin/* /usr/local/sbin
    fi

    if find /opt/$pkgspec/share/man -mindepth 1 2>/dev/null | grep -q . ; then
        cd /opt/$pkgspec/share/man
        for d in * ; do
            if find /opt/$pkgspec/share/man/$d -mindepth 1 2>/dev/null | grep -q . ; then
                mkdir -p /usr/local/share/man/$d/
                ln -vsf /opt/$pkgspec/share/man/$d/* /usr/local/share/man/$d
            fi
        done
        cd - >/dev/null
    fi

    if ! test -e /opt/$pkgspec/share/tiger.sh/$pkgspec/$script.log.gz ; then
        mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
        nice gzip /tmp/$script.log
        mv /tmp/$script.log.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
    fi

    rm -f /opt/$pkgspec/INCOMPLETE_INSTALLATION
    rm -f /tmp/$script
fi


# url exists:

if test "$op" = "url-exists" ; then
    shift 1
    if test -z "$1" ; then
        echo "Error: check which url?" >&2
        echo "e.g. tiger.sh --url-exists http://example.com" >&2
        exit 1
    fi
    url="$1"
    curl --fail --silent --show-error -I "$url" >/dev/null 2>&1

    exit 0
fi


# install a binpkg into /opt:

if test "$op" = "install-binpkg" ; then
    shift 1
    if test -z "$1" ; then
        echo "Error: install which binpkg?" >&2
        echo "e.g. tiger.sh --install-binpkg gzip-1.11" >&2
        exit 1
    fi

    pkgspec="$1"
    shift 1

    os_cpu=$(TIGERSH_RECURSED=1 tiger.sh --os.cpu)
    binpkg=$pkgspec.$os_cpu.tar.gz
    url=$TIGERSH_MIRROR/binpkgs/$binpkg

    # since we are checking the MD5 sum, drop from https to http.
    url=$(echo "$url" | sed 's|^https:|^http:|')

    if ! TIGERSH_RECURSED=1 tiger.sh --url-exists "$url" ; then
        echo "Pre-compiled binary package unavailable for $pkgspec on $os_cpu." >&2
        exit 1
    fi

    if test -n "$TIGERSH_FORCE_BUILD" ; then
        echo "Ignoring $binpkg due to '\$TIGERSH_FORCE_BUILD'" >&2
        exit 1
    fi

    echo "Unpacking $binpkg into /opt." >&2
    TIGERSH_RECURSED=1 tiger.sh --unpack-tarball-check-md5 $url /opt

    exit $0
fi


# unpack a distfile into /tmp:

if test "$op" = "unpack-dist" ; then
    shift 1
    if test -z "$1" ; then
        echo "Error: unpack distfile for which pkgspec?" >&2
        echo "e.g. tiger.sh --unpack-dist gzip-1.11" >&2
        exit 1
    fi

    pkgspec="$1"
    shift 1

    tarball=$pkgspec.tar.gz
    url=$TIGERSH_MIRROR/dist/$tarball

    # since we are checking the MD5 sum, drop from https to http.
    url=$(echo "$url" | sed 's|^https:|^http:|')

    echo "Unpacking $tarball into /tmp." >&2
    rm -rf /tmp/$pkgspec
    TIGERSH_RECURSED=1 tiger.sh --unpack-tarball-check-md5 $url /tmp

    exit $0
fi


# unpack a tarball and verify its MD5 sum:

if test "$op" = "unpack-tarball-check-md5" ; then
    shift 1
    if test -z "$1" ; then
        echo "Error: unpack which tarball url?" >&2
        echo "e.g. tiger.sh --unpack-tarball-check-md5 http://leopard.sh/dist/gzip-1.11.tar.gz /tmp" >&2
        echo "e.g. tiger.sh --unpack-tarball-check-md5 http://leopard.sh/binpkgs/gzip-1.11.tiger.g3.tar.gz /opt" >&2
        exit 1
    fi
    url="$1"
    shift 1

    # since we are checking the MD5 sum, drop from https to http.
    url=$(echo "$url" | sed 's|^https:|^http:|')

    if test -z "$1" ; then
        echo "Error: unpack tarball where?" >&2
        echo "e.g. tiger.sh --unpack-tarball-check-md5 http://leopard.sh/dist/gzip-1.11.tar.gz /tmp" >&2
        echo "e.g. tiger.sh --unpack-tarball-check-md5 http://leopard.sh/binpkgs/gzip-1.11.tiger.g3.tar.gz /opt" >&2
        exit 1
    fi
    dest="$1"
    shift 1

    tmp=$(mktemp -u /tmp/tarball.XXXX)
    fifo=$tmp.fifo
    rm -f $fifo
    ( mkfifo $fifo \
        && cat $fifo | nice md5 > $tmp.localmd5_ \
        && mv $tmp.localmd5_ $tmp.localmd5
    ) &

    while ! test -e $fifo ; do sleep 0.1 ; done

    size=$(curl --fail --silent --show-error --head $url \
        | grep -i '^content-length:' \
        | awk '{print $NF}' \
        | sed "s/$(printf '\r')//"
    )

    cd /tmp
    curl --fail --silent --show-error --location $url.md5 > $tmp.md5

    cd $dest
    nice curl --fail --silent --show-error $url \
        | pv --force --size $size \
        | tee $fifo \
        | nice gunzip \
        | nice tar x

    while ! test -e $tmp.localmd5 ; do sleep 0.1 ; done

    if ! test "$(cat $tmp.localmd5)" = "$(cat $tmp.md5)" ; then
        badmd5=1
    fi

    rm -f $fifo $tmp.localmd5 $tmp.md5

    if test -n "$badmd5" ; then
        echo "Error: MD5 sum mismatch for $url."
        exit 1
    else
        exit 0
    fi
fi


# generate flags for 'make':

if test "$op" = "makeflags" ; then
    if test "$1" = "-j" ; then
        j=$(sysctl hw.logicalcpu | awk '{print $NF}')
        echo "-j$j"
    fi

    exit 0
fi


# generate flags for 'gcc':

if test "$op" = "gccflags" ; then
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
    fi

    exit 0
fi


# sysctl queries:

if test "$op" = "platform-info" ; then
    if test "$1" = "--cpu" ; then
        echo $cpu_name
    elif test "$1" = "--os.cpu" ; then
        echo tiger.$cpu_name
    fi

    exit 0
fi


# arch check:

if test "$op" = "arch-check" ; then
    shift 1
    if test -z "$1" ; then
        echo "Error: arch-check which package?" >&2
        echo "e.g. tiger.sh --arch-check tar-1.34" >&2
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

if test "$op" = "linker-check" ; then
    shift 1
    if test -z "$1" ; then
        echo "Error: linker-check which package?" >&2
        echo "e.g. tiger.sh --linker-check tar-1.34" >&2
        exit 1
    fi

    pkgspec="$1"
    cd /opt/$pkgspec
    for d in bin sbin lib ; do
        if test -e /opt/$pkgspec/$d && test -n "$(ls /opt/$pkgspec/$d/)" ; then
            for f in $d/* ; do
                if test -f $f -a ! -L $f \
                    -a "${f: -2}" != ".a" \
                    -a "${f: -3}" != ".la"
                then
                    if test -z "$did_print_header" ; then
                        echo -e "\nLinker check: /opt/$pkgspec\n"
                        did_print_header=1
                    fi
                    echo -e "$(otool -L $f \
                        | awk '{print $1}' \
                        | sed 's/^/    /' \
                        | sed -E "/\/usr\/lib\/(libSystem|libgcc_s|libstdc\+\+)/! s|/usr/|/${COLOR_YELLOW}usr${COLOR_NONE}/|g" \
                        | sed "s|/opt/|/${COLOR_GREEN}opt${COLOR_NONE}/|g" \
                        | sed "s|/System/Library/Frameworks/|/${COLOR_CYAN}System${COLOR_NONE}/Library/Frameworks/|g" \
                        | sed -E "s/(libSystem|libgcc_s|libstdc\+\+)/${COLOR_CYAN}\1${COLOR_NONE}/g"
                    )"
                    echo
                fi
            done
        fi
    done

    exit 0
fi


# unlink:

if test "$op" = "unlink" ; then
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
