#!/bin/bash

# leopard.sh: package manager for PowerPC Macs running OS X Leopard (10.5).
# Try 'leopard.sh --help'.
# See https://github.com/cellularmitosis/leopard.sh

set -e -o pipefail

pkgmgr=leopard.sh

if test "$1" = "--verbose" ; then
    shift 1
    export LEOPARDSH_VERBOSE=1
fi

if test -n "$LEOPARDSH_VERBOSE" ; then
    set -x
fi

# Note: for offline use or to run you own local fork, put this in your ~/.bashrc:
#   export LEOPARDSH_MIRROR=file:///Users/foo/leopard.sh
# If you care more about speed than glowies, drop HTTPS for a speed-up:
#   export LEOPARDSH_MIRROR=http://leopard.sh
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}
export LEOPARDSH_MIRROR

# no alarms and no surprises, please.
ORIG_PATH="$PATH"
export PATH="/opt/tigersh-deps-0.1/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# colors:

export COLOR_RED="\e[31;1m"
export COLOR_GREEN="\e[32;1m"
export COLOR_YELLOW="\e[33;1m"
export COLOR_MAGENTA="\e[35;1m"
export COLOR_CYAN="\e[36;1m"
export COLOR_NONE="\e[0m"


# process the command line args:


needs_setup_check=1

if test "$1" = "--help" ; then
    op=help
elif test "$1" = "--list" ; then
    op=list
elif test "$1" = "--describe" -o "$1" = "--descriptions"; then
    op=describe
elif test "$1" = "--tags" ; then
    op=tags
elif test "$1" = "--tag" ; then
    op=tag
elif test "$1" = "--setup" ; then
    op=setup
elif test "$1" = "--self-update" ; then
    op=self-update
elif test "$1" = "--install" ; then
    op=install
elif test "$1" = "--link" ; then
    op=link
elif test "$1" = "--unlink" ; then
    op=unlink
elif test "$1" = "-j" ; then
    op=makeflags
    unset needs_setup_check
elif test "$1" = "-m32" -o "$1" = "-mcpu" -o "$1" = "-O" ; then
    op=gccflags
elif test "$1" = "--cpu" -o "$1" = "--os.cpu" -o "$1" = "--bits" ; then
    op=platform-info
elif test "$1" = "--arch-check" ; then
    op=arch-check
elif test "$1" = "--linker-check" ; then
    op=linker-check
elif test "$1" = "--url-exists" ; then
    op=url-exists
elif test "$1" = "--install-binpkg" ; then
    op=install-binpkg
elif test "$1" = "--unpack-dist" ; then
    op=unpack-dist
elif test "$1" = "--unpack-tarball-check-md5" ; then
    op=unpack-tarball-check-md5
elif test "$1" = "--glass-dock" ; then
    op=glass-dock
elif test "$1" = "--spotlight" ; then
    op=spotlight
elif test -n "$1" ; then
    op=install
else
    op=list
fi

if test "$1" = "--help" \
-o "$1" = "-j" \
-o "$1" = "-m32" \
-o "$1" = "-mcpu" \
-o "$1" = "-O" \
-o "$1" = "--cpu" \
-o "$1" = "--os.cpu" \
-o "$1" = "--bits" \
-o "$1" = "--glass-dock" \
-o "$1" = "--spotlight" \
; then
    unset needs_setup_check
fi

if test "$op" = "list" \
-o "$op" = "install" \
-o "$op" = "gccflags" \
-o "$op" = "platform-info" \
-o "$op" = "arch-check" \
-o "$op" = "glass-dock" \
-o "$op" = "spotlight" \
; then
    needs_cpu_info=1
fi

if test -n "$LEOPARDSH_RECURSED" ; then
    unset needs_setup_check
fi

orig_pwd=$PWD

if ! test -e ~/.leopardsh/checks ; then
    mkdir -p ~/.leopardsh/checks
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
        echo -e "${COLOR_RED}Error${COLOR_NONE}: unsupported CPU type." >&2
        exit 1
    fi
fi


# setup:

if test "$op" = "setup" || test -n "$needs_setup_check" ; then
    if ! test -e ~/.leopardsh/checks/os-is-leopard ; then
        osversion=$(sw_vers -productVersion)
        if ! test "${osversion:0:4}" = "10.5" ; then
            echo "Sorry, this script was written for OS X Leopard :(" >&2
            exit 1
        else
            touch ~/.leopardsh/checks/os-is-leopard
        fi
    fi

    needs_new_terminal="false"

    if ! test -e ~/.leopardsh/checks/usr-local-bin-in-path ; then
        if ! echo $ORIG_PATH | tr ':' '\n' | egrep '^/usr/local/bin/?$' >/dev/null ; then
            echo "Adding /usr/local/bin to your \$PATH." >&2
            if ! test -e ~/.bashrc -o -e ~/.bash_profile -o -e ~/.profile ; then
                # This is a brand-new user with no rc files.
                touch ~/.profile
            fi
            for f in ~/.bashrc ~/.bash_profile ~/.profile ; do
                if test -e $f ; then
                    echo >> $f
                    echo "# Added by leopard.sh:" >> $f
                    echo "export PATH=\"/usr/local/bin:/usr/local/sbin:\$PATH\"" >> $f
                fi
            done
            needs_new_terminal="true"
        else
            touch ~/.leopardsh/checks/usr-local-bin-in-path
        fi
    fi

    if ! test -e ~/.leopardsh/checks/user-in-admin-group ; then
        if ! dseditgroup -o checkmember -m $USER admin >/dev/null ; then
            echo "Adding your user to the admin group." >&2
            # thanks to https://blog.travismclarke.com/post/osx-cli-group-management/
            set -x
            sudo dseditgroup -o edit -a $USER -t user admin
            { set +x; } 2>/dev/null
            sleep 1
            if ! dseditgroup -o checkmember -m $USER admin >/dev/null ; then
                needs_new_terminal="true"
            fi
        else
            touch ~/.leopardsh/checks/user-in-admin-group
        fi
    fi

    if ! test -e ~/.leopardsh/checks/user-in-wheel-group ; then
        if ! dseditgroup -o checkmember -m $USER wheel >/dev/null ; then
            echo "Adding your user to the wheel group." >&2
            # thanks to https://blog.travismclarke.com/post/osx-cli-group-management/
            set -x
            sudo dseditgroup -o edit -a $USER -t user wheel
            { set +x; } 2>/dev/null
            sleep 1
            if ! dseditgroup -o checkmember -m $USER wheel >/dev/null ; then
                needs_new_terminal="true"
            fi
        else
            touch ~/.leopardsh/checks/user-in-wheel-group
        fi
    fi

    if test "$needs_new_terminal" = "true" ; then
        echo "This change won't take effect until you open a new Terminal window." >&2
        echo "Please open a new Terminal window and run $0 again." >&2
        exit 1
    fi

    # thanks to https://stackoverflow.com/a/61367055
    for pair in \
    "opt /opt" \
    "usr-local /usr/local" \
    "usr-local-bin /usr/local/bin" \
    "usr-local-sbin /usr/local/sbin" \
    "usr-local-share /usr/local/share" \
    "usr-local-share-man /usr/local/share/man" \
    "usr-local-share-man1 /usr/local/share/man/man1" \
    "usr-local-share-man3 /usr/local/share/man/man3" \
    ; do
        arr=($pair)
        stamp="can-write-in-${arr[0]}"
        d="${arr[1]}"

        if test -e ~/.leopardsh/checks/$stamp ; then
            continue
        fi

        if ! test -e $d ; then
            echo "Creating $d." >&2
            set -x
            sudo mkdir $d
            sudo chgrp admin $d
            sudo chmod g+w $d
            { set +x; } 2>/dev/null
        else
            if ! test "$(stat -f '%Sg' $d)" = "admin" ; then
                echo "Changing group of $d to admin." >&2
                set -x
                sudo chgrp admin $d
                { set +x; } 2>/dev/null
            fi
            if ! test "$(expr $(stat -f '%Sp' $d) : '.....\(.\)')" = "w" ; then
                echo "Making $d group-writeable." >&2
                set -x
                sudo chmod g+w $d
                { set +x; } 2>/dev/null
            fi
        fi

        if ! mktemp $d/leopard.sh.write-check.XXX >/dev/null ; then
            echo -e "${COLOR_RED}Error${COLOR_NONE}: can't write to $d." >&2
            exit 1
        else
            touch ~/.leopardsh/checks/$stamp
            rm -f $d/leopard.sh.write-check.*
        fi
    done

    if ! test -e ~/Downloads ; then
        mkdir -p ~/Downloads
    fi

    if test "$BASH_SOURCE" != "/usr/local/bin/leopard.sh" ; then
        echo "Moving leopard.sh into /usr/local/bin." >&2
        set -x
        sudo mv "$0" /usr/local/bin/
        { set +x; } 2>/dev/null
    fi

    deps_pkgspec=tigersh-deps-0.1
    if test ! -e /opt/$deps_pkgspec \
    || test -e /opt/$deps_pkgspec/INCOMPLETE_INSTALLATION ; then
        echo -e "${COLOR_CYAN}Installing${COLOR_NONE} leopard.sh dependencies (pv, curl w/SSL, otool w/ppc64 support)." >&2

        rm -rf /opt/$deps_pkgspec
        mkdir -p /opt/$deps_pkgspec
        touch /opt/$deps_pkgspec/INCOMPLETE_INSTALLATION

        cd /tmp

        binpkg=$deps_pkgspec.tiger.g3.tar.gz
        fifo=/tmp/$binpkg.fifo
        rm -f $fifo /tmp/$binpkg.localmd5_ /tmp/$binpkg.localmd5
        ( mkfifo $fifo \
            && cat $fifo | nice md5 > /tmp/$binpkg.localmd5_ \
            && mv /tmp/$binpkg.localmd5_ /tmp/$binpkg.localmd5
        ) &

        while ! test -e $fifo ; do sleep 0.1 ; done

        if test -e /tmp/$binpkg ; then
            # If the user provided the file locally, use that.
            url=file:///tmp/$binpkg
            insecure_url=$url
        else
            url=$LEOPARDSH_MIRROR/binpkgs/$binpkg

            # At this point we are still using /usr/bin/curl, so drop back to http.
            insecure_url=$(echo "$url" | sed 's|^https:|http:|')

            if test -n "$LEOPARDSH_MIRROR_NO_HTTP" ; then
                echo "Error: unable to fetch $url" >&2
                echo "/usr/bin/curl is unable to use HTTPS, but LEOPARDSH_MIRROR_NO_HTTP has been set." >&2
                echo "Please place a copy of $binpkg into /tmp and try again." >&2
                exit 1
            fi
        fi

        cd /opt
        nice curl --fail --silent --show-error $insecure_url \
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
        echo "OS X Leopard's support for SSL is too old to use, which means this script" >&2
        echo "can't verify the integrity of the dependencies which it just downloaded." >&2
        echo >&2
        echo "Please visit https://leopard.sh/md5 in a modern browser (or by scanning the" >&2
        echo "above QR code on your smartphone) and verify the following MD5 sums:" >&2
        echo >&2
        echo "The MD5 sum of leopard.sh is:" >&2
        echo >&2
        echo "    $(md5 -q /usr/local/bin/leopard.sh)" >&2
        echo >&2
        echo "The MD5 sum of $binpkg is:" >&2
        echo >&2
        echo "    $(cat /tmp/$binpkg.localmd5)" >&2
        echo >&2

        read -p "Do the MD5 sums match? [Y/n]: " answer
        while true ; do
            if test "$answer" = "y" -o "$answer" = "Y" -o "$answer" = "" ; then
                rm -f /tmp/$binpkg.localmd5
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

    opt_config_cache=/opt/leopard.sh/share/leopard.sh/config.cache
    if ! test -e $opt_config_cache ; then
        mkdir -p $opt_config_cache
    fi
    if test "$(sysctl hw.cpusubtype | awk '{print $NF}')" = "100" ; then
        bits=64
    else
        bits=32
    fi
    if test ! -e $opt_config_cache/leopard.cache || test ! -e $opt_config_cache/leopard.$bits.cache ; then
        cd $opt_config_cache
        if ! test -e $opt_config_cache/leopard.cache ; then
            echo "Fetching configure cache (leopard.cache)." >&2
            url=$LEOPARDSH_MIRROR/leopardsh/config.cache/leopard.cache
            curl --fail --silent --show-error --location --remote-name $url
        fi
        if ! test -e $opt_config_cache/leopard.$bits.cache ; then
            echo "Fetching configure cache (leopard.$bits.cache)." >&2
            url=$LEOPARDSH_MIRROR/leopardsh/config.cache/leopard.$bits.cache
            curl --fail --silent --show-error --location --remote-name $url
        fi
    fi
fi


# list:

if test "$op" = "list" ; then
    echo "Available packages:" >&2
    cd /tmp
    url=$LEOPARDSH_MIRROR/leopardsh/packages.txt
    if test -n "$LEOPARDSH_MIRROR_NO_HTTP" ; then
        insecure_url=$url
    else
        insecure_url=$(echo "$url" | sed 's|^https:|http:|')
    fi
    curl --fail --silent --show-error --location --remote-name $insecure_url
    if test "$cpu_name" = "g5" ; then
        url=$LEOPARDSH_MIRROR/leopardsh/packages.ppc64.txt
        if test -n "$LEOPARDSH_MIRROR_NO_HTTP" ; then
            insecure_url=$url
        else
            insecure_url=$(echo "$url" | sed 's|^https:|http:|')
        fi
        curl --fail --silent --show-error --location --remote-name $insecure_url
        cat packages.txt packages.ppc64.txt | sort
    else
        cat packages.txt
    fi
    rm -f packages.txt packages.ppc64.txt

    exit 0
fi


# describe:

if test "$op" = "describe" ; then
    shift 1
    if test -n "$1" ; then
        pkgspec="$1"
        shift 1
        echo "Description of '$pkgspec':" >&2
    else
        echo "Available package descriptions:" >&2
    fi

    cd /tmp
    url=$LEOPARDSH_MIRROR/leopardsh/descriptions.txt
    if test -n "$LEOPARDSH_MIRROR_NO_HTTP" ; then
        insecure_url=$url
    else
        insecure_url=$(echo "$url" | sed 's|^https:|http:|')
    fi
    curl --fail --silent --show-error --location --remote-name $insecure_url
    if test "$cpu_name" = "g5" ; then
        url=$LEOPARDSH_MIRROR/leopardsh/descriptions.ppc64.txt
        if test -n "$LEOPARDSH_MIRROR_NO_HTTP" ; then
            insecure_url=$url
        else
            insecure_url=$(echo "$url" | sed 's|^https:|http:|')
        fi
        curl --fail --silent --show-error --location --remote-name $insecure_url
        if test -n "$pkgspec" ; then
            cat descriptions.txt descriptions.ppc64.txt | sort | grep "^$pkgspec: "
        else
            cat descriptions.txt descriptions.ppc64.txt | sort
        fi
    else
        if test -n "$pkgspec" ; then
            cat descriptions.txt | sort | grep "^$pkgspec: "
        else
            cat descriptions.txt | sort
        fi
    fi
    rm -f descriptions.txt descriptions.ppc64.txt

    exit 0
fi


# tags:

if test "$op" = "tags" ; then
    echo "Available tags:" >&2
    cd /tmp
    url=$LEOPARDSH_MIRROR/leopardsh/tags/tags.txt
    if test -n "$LEOPARDSH_MIRROR_NO_HTTP" ; then
        insecure_url=$url
    else
        insecure_url=$(echo "$url" | sed 's|^https:|http:|')
    fi
    curl --fail --silent --show-error --location --remote-name $insecure_url
    cat tags.txt
    rm -f tags.txt

    exit 0
fi


# tag:

if test "$op" = "tag" ; then
    shift 1
    if test -z "$1" ; then
        LEOPARDSH_RECURSED=1 leopard.sh --tags
        exit 0
    fi
    tag="$1"

    echo "Packages tagged as '$tag':" >&2
    cd /tmp
    url=$LEOPARDSH_MIRROR/leopardsh/tags/$tag.txt
    if test -n "$LEOPARDSH_MIRROR_NO_HTTP" ; then
        insecure_url=$url
    else
        insecure_url=$(echo "$url" | sed 's|^https:|http:|')
    fi
    curl --fail --silent --show-error --location --remote-name $insecure_url
    if test "$cpu_name" = "g5" ; then
        cat $tag.txt
    else
        cat $tag.txt | grep -v '\.ppc64$'
    fi
    rm -f $tag.txt

    exit 0
fi


# install:

if test "$op" = "install" ; then
    if test "$1" = "--install" ; then
        shift 1
    fi

    pkgspec="$1"
    shift 1
    script=install-$pkgspec.sh

    if test "$1" = "wip" ; then
        wip=1
    fi

    # Note: check for symlinks because e.g. the /opt/gcc-... symlink created
    # by gcc-libs should be replaced by the real gcc if explicitly requested.
    if test -e "/opt/$pkgspec" -a ! -L "/opt/$pkgspec" \
    && test ! -e "/opt/$pkgspec/INCOMPLETE_INSTALLATION" ; then
        echo -e "${COLOR_YELLOW}${pkgspec}${COLOR_NONE} is already installed at /opt/$pkgspec" >&2
        exit 0
    fi

    echo -e "${COLOR_CYAN}Installing${COLOR_NONE} ${COLOR_YELLOW}$pkgspec${COLOR_NONE}." >&2
    echo -n -e "\033]0;leopard.sh $pkgspec (leopard.$cpu_name)\007"

    echo -e "${COLOR_CYAN}Fetching${COLOR_NONE} $script." >&2
    url=$LEOPARDSH_MIRROR/leopardsh/scripts/$script
    if test -n "$wip" ; then
        url=$LEOPARDSH_MIRROR/leopardsh/scripts/wip/$script
    fi
    cd /tmp
    curl --fail --silent --show-error --location --remote-name $url &
    curl_script_pid=$!

    rm -rf /opt/$pkgspec

    wait $curl_script_pid

    mkdir -p /opt/$pkgspec
    touch /opt/$pkgspec/INCOMPLETE_INSTALLATION

    chmod +x $script

    if test -n "$LEOPARDSH_VERBOSE" ; then
        LEOPARDSH_RECURSED=1 nice bash -x ./$script 2>&1 | tee /tmp/$script.log
    else
        LEOPARDSH_RECURSED=1 nice ./$script 2>&1 | tee /tmp/$script.log
    fi

    LEOPARDSH_RECURSED=1 leopard.sh --link $pkgspec

    if ! test -e /opt/$pkgspec/share/leopard.sh/$pkgspec/$script.log.gz ; then
        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
        nice gzip -9 /tmp/$script
        mv /tmp/$script.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
        nice gzip -9 /tmp/$script.log
        mv /tmp/$script.log.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
    fi

    rm -f /opt/$pkgspec/INCOMPLETE_INSTALLATION

    if test -e /opt/$pkgspec/SUPERFLUOUS_DIRECTORY ; then
        rm -rf /opt/$pkgspec
    fi

    exit 0
fi


# url exists:

if test "$op" = "url-exists" ; then
    shift 1
    if test -z "$1" ; then
        echo -e "${COLOR_RED}Error${COLOR_NONE}: check which url?" >&2
        echo "e.g. leopard.sh --url-exists http://example.com" >&2
        exit 1
    fi
    url="$1"
    curl --fail --silent --show-error --head "$url" >/dev/null 2>&1

    exit 0
fi


# install a binpkg into /opt:

if test "$op" = "install-binpkg" ; then
    shift 1
    if test -z "$1" ; then
        echo -e "${COLOR_RED}Error${COLOR_NONE}: install which binpkg?" >&2
        echo "e.g. leopard.sh --install-binpkg gzip-1.11" >&2
        echo "e.g. leopard.sh --install-binpkg gzip-1.11 tiger.g3" >&2
        exit 1
    fi

    pkgspec="$1"
    shift 1

    if test -n "$1" ; then
        os_cpu="$1"
        shift 1
    else
        os_cpu=$(LEOPARDSH_RECURSED=1 leopard.sh --os.cpu)
    fi

    binpkg=$pkgspec.$os_cpu.tar.gz
    url=$LEOPARDSH_MIRROR/binpkgs/$binpkg
    if test -n "$LEOPARDSH_MIRROR_NO_HTTP" ; then
        insecure_url=$url
    else
        insecure_url=$(echo "$url" | sed 's|^https:|http:|')
    fi

    if ! LEOPARDSH_RECURSED=1 leopard.sh --url-exists "$insecure_url" ; then
        echo "Pre-compiled binary package unavailable for $pkgspec on $os_cpu." >&2
        exit 1
    fi

    if test "$LEOPARDSH_FORCE_BUILD_PKGSPEC" = "$pkgspec" ; then
        echo "Ignoring $binpkg due to '\$LEOPARDSH_FORCE_BUILD_PKGSPEC'" >&2
        exit 1
    fi

    if test -n "$LEOPARDSH_FORCE_BUILD_ALL" ; then
        echo "Ignoring $binpkg due to '\$LEOPARDSH_FORCE_BUILD_ALL'" >&2
        exit 1
    fi

    echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $binpkg into /opt." >&2
    LEOPARDSH_RECURSED=1 leopard.sh --unpack-tarball-check-md5 $url /opt

    exit 0
fi


# unpack a distfile into /tmp:

if test "$op" = "unpack-dist" ; then
    shift 1
    if test -z "$1" ; then
        echo -e "${COLOR_RED}Error${COLOR_NONE}: unpack distfile for which pkgspec?" >&2
        echo "e.g. leopard.sh --unpack-dist gzip-1.11" >&2
        exit 1
    fi

    pkgspec="$(echo $1 | sed 's/\.ppc64//')"
    shift 1

    tarball=$pkgspec.tar.gz
    url=$LEOPARDSH_MIRROR/dist/$tarball

    echo -e "${COLOR_CYAN}Unpacking${COLOR_NONE} $tarball into /tmp." >&2
    rm -rf /tmp/$pkgspec
    LEOPARDSH_RECURSED=1 leopard.sh --unpack-tarball-check-md5 $url /tmp

    if test -e /tmp/$pkgspec/configure ; then
        cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache \
            /opt/leopard.sh/share/leopard.sh/config.cache/leopard.$(leopard.sh --bits).cache \
            > /tmp/$pkgspec/config.cache
    fi

    exit 0
fi


# unpack a tarball and verify its MD5 sum:

if test "$op" = "unpack-tarball-check-md5" ; then
    shift 1
    if test -z "$1" ; then
        echo -e "${COLOR_RED}Error${COLOR_NONE}: unpack which tarball url?" >&2
        echo "e.g. leopard.sh --unpack-tarball-check-md5 http://leopard.sh/dist/gzip-1.11.tar.gz /tmp" >&2
        echo "e.g. leopard.sh --unpack-tarball-check-md5 http://leopard.sh/binpkgs/gzip-1.11.leopard.g4e.tar.gz /opt" >&2
        exit 1
    fi
    url="$1"
    if test -n "$LEOPARDSH_MIRROR_NO_HTTP" ; then
        insecure_url=$url
    else
        insecure_url=$(echo "$url" | sed 's|^https:|http:|')
    fi
    shift 1

    if test -z "$1" ; then
        echo -e "${COLOR_RED}Error${COLOR_NONE}: unpack tarball where?" >&2
        echo "e.g. leopard.sh --unpack-tarball-check-md5 http://leopard.sh/dist/gzip-1.11.tar.gz /tmp" >&2
        echo "e.g. leopard.sh --unpack-tarball-check-md5 http://leopard.sh/binpkgs/gzip-1.11.leopard.g4e.tar.gz /opt" >&2
        exit 1
    fi
    dest="$1"
    shift 1

    if test "$1" = "sudo" ; then
        sudo="sudo"
        shift 1
    fi

    if test -n "$1" ; then
        md5arg="$1"
        shift 1
    fi

    cd /tmp

    tmp=$(mktemp -u /tmp/leopard.sh.tarball.XXXX)

    if test -n "$md5arg" ; then
        echo "$md5arg" > $tmp.md5
    else
        curl --fail --silent --show-error --location $url.md5 > $tmp.md5 &
        curl_md5_pid=$!
    fi

    fifo=$tmp.fifo
    ( mkfifo $fifo \
        && cat $fifo | nice md5 > $tmp.localmd5_ \
        && mv $tmp.localmd5_ $tmp.localmd5
    ) &

    while ! test -e $fifo ; do sleep 0.1 ; done

    if test -n "$LEOPARDSH_MIRROR_NO_HEAD" ; then
        # Some servers don't support HTTP HEAD
        size=0
    else
        size=$(curl --fail --silent --show-error --location --head $insecure_url \
            | grep -i '^content-length:' \
            | tail -n1 \
            | awk '{print $NF}' \
            | sed "s/$(printf '\r')//"
        )
    fi

    if test -n "$sudo" ; then
        # prompt the user for their password before we start the curl pipeline.
        sudo true
    fi

    cd $dest
    nice curl --fail --silent --show-error --location $insecure_url \
        | pv --force --size $size \
        | tee $fifo \
        | nice gunzip \
        | nice $sudo tar x

    while ! test -e $tmp.localmd5 ; do sleep 0.1 ; done

    wait $curl_md5_pid

    if ! test "$(cat $tmp.localmd5)" = "$(cat $tmp.md5)" ; then
        badmd5=1
    fi

    rm -f $fifo $tmp.localmd5 $tmp.md5

    if test -n "$badmd5" ; then
        echo -e "${COLOR_RED}Error${COLOR_NONE}: MD5 sum mismatch for $url."
        exit 1
    else
        exit 0
    fi
fi


# link:

if test "$op" = "link" ; then
    shift 1
    if test -z "$1" ; then
        echo -e "${COLOR_RED}Error${COLOR_NONE}: link which package?" >&2
        echo "e.g. leopard.sh --link foo-1.0" >&2
        exit 1
    fi

    pkgspec="$1"

    if find /opt/$pkgspec/bin -mindepth 1 2>/dev/null | grep -q . ; then
        if test -z "$did_print_header" ; then
            echo -e "${COLOR_CYAN}Linking${COLOR_NONE} $pkgspec into /usr/local." >&2
            did_print_header=1
        fi
        ln -vsf /opt/$pkgspec/bin/* /usr/local/bin | sed 's/^/  /'
    fi

    if find /opt/$pkgspec/sbin -mindepth 1 2>/dev/null | grep -q . ; then
        if test -z "$did_print_header" ; then
            echo -e "${COLOR_CYAN}Linking${COLOR_NONE} $pkgspec into /usr/local." >&2
            did_print_header=1
        fi
        ln -vsf /opt/$pkgspec/sbin/* /usr/local/sbin | sed 's/^/  /'
    fi

    for optpkgman in /opt/$pkgspec/man /opt/$pkgspec/share/man ; do
        if find $optpkgman -mindepth 1 2>/dev/null | grep -q . ; then
            cd $optpkgman
            for d in * ; do
                if find $optpkgman/$d -mindepth 1 2>/dev/null | grep -q . ; then
                    if test -z "$did_print_header" ; then
                        echo -e "${COLOR_CYAN}Linking${COLOR_NONE} $pkgspec into /usr/local." >&2
                        did_print_header=1
                    fi
                    if ! test -e /usr/local/share/man/$d ; then
                        mkdir -p /usr/local/share/man/$d/
                        chmod g+w /usr/local/share/man/$d
                    fi
                    ln -vsf $optpkgman/$d/* /usr/local/share/man/$d | sed 's/^/  /'
                fi
            done
            cd - >/dev/null
        fi
    done

    if find /opt/$pkgspec/lib/pkgconfig -mindepth 1 2>/dev/null | grep -q . ; then
        if test -z "$did_print_header" ; then
            echo -e "${COLOR_CYAN}Linking${COLOR_NONE} $pkgspec into /usr/local." >&2
            did_print_header=1
        fi
        mkdir -p /usr/local/lib/pkgconfig
        ln -vsf /opt/$pkgspec/lib/pkgconfig/* /usr/local/lib/pkgconfig | sed 's/^/  /'
    fi

    exit 0
fi


# unlink:

if test "$op" = "unlink" ; then
    shift 1
    if test -z "$1" ; then
        echo -e "${COLOR_RED}Error${COLOR_NONE}: unlink which package?" >&2
        echo "e.g. leopard.sh --unlink foo-1.0" >&2
        exit 1
    fi

    pkgspec="$1"

    if ! test -e /opt/$pkgspec ; then
        echo -e "${COLOR_YELLOW}Warning${COLOR_NONE}: /opt/$pkgspec doesn't exist, can't unlink." >&2
        exit 0
    fi

    echo -e "${COLOR_CYAN}Unlinking${COLOR_NONE} $pkgspec from /usr/local." >&2

    # deletes any symlinks in /usr/local/* which point to /opt/foo-1.0/*.
    # what a pain in the ass!
    cd "/opt/$pkgspec"
    find . -mindepth 1 \( -type f -or -type l \) -exec \
        bash -e -c \
            "subpath=\$(echo {} | sed 's|^\\./||')
            if test -L \"/usr/local/\$subpath\" \
                && test \"\$(readlink \"/usr/local/\$subpath\")\" = \"/opt/$pkgspec/\$subpath\" ; \
            then \
                rm -v \"/usr/local/\$subpath\" | sed 's/^/  rm /'
            fi" \
    \;

    exit 0
fi


# self-update:

if test "$op" = "self-update" ; then
    echo "Fetching the latest leopard.sh (into /usr/local/bin)." >&2
    cd /tmp
    url=$LEOPARDSH_MIRROR/leopardsh/leopard.sh
    curl --fail --silent --show-error --location --remote-name $url
    chmod +x leopard.sh
    mv leopard.sh /usr/local/bin/
    exit 0
fi


# display the help message:

if test "$op" = "help" ; then
    echo "$pkgmgr: a packge manager for PowerPC Macs running OS X 10.5 \"Leopard\"."
    echo " * To list the available packages, just run '$pkgmgr'."
    echo " * To install a package, run e.g. '$pkgmgr foo-1.0'".
    echo " * To uninstall a package, '$pkgmgr --unlink foo-1.0 && rm -r /opt/foo-1.0'".
    echo
    echo "Command-line commands:"
    echo "  --help: display this message."
    echo "  --describe: describe all available packages (or --descriptions)."
    echo "  --describe foo-1.0: describe 'foo-1.0'."
    echo "  --tag: list the available tags (or --tags)."
    echo "  --tag foo: list the packages tagged as 'foo'."
    echo "  --link foo-1.0: symlink bin, man, share/man from /opt/foo-1.0 into /usr/local."
    echo "  --unlink foo-1.0: remove the /usr/local symlinks for foo-1.0."
    echo "  --self-update: install the latest version of this script."
    echo
    echo "Unnecessary command-line commands:"
    echo "  --list: list the available packages (redundant, just run '$pkgmgr')."
    echo "  --install foo-1.0: install 'foo-1.0' (redundant, just run '$pkgmgr foo-1.0')."
    echo "  --setup: perform initial setup (this is done automatically as needed)."
    echo
    echo "Performance tweaks:"
    echo "  --glass-dock (on|off): turn the Dock's \"glass\" effect on or off."
    echo "  --spotlight (on|off): turn Spotlight on or off."
    echo
    echo "Command-line options:"
    echo "  --verbose: print every command being run (note: must be the first arg)."
    echo
    echo "Obscure command-line commands (used internally by $pkgmgr):"
    echo "  --cpu: print the CPU type (g3, g4, g4e, or g5)."
    echo "  --os.cpu: print OS and CPU type (e.g. leopard.g4e)."
    echo "  --bits: print the bit-width of the CPU (32 or 64)."
    echo "  -j: (for make) print the -j flag based on number of CPU's (e.g. '-j1')."
    echo "  -m32: (for gcc) print '-m32', but only if a G5 chip is detected."
    echo "  -mcpu: (for gcc) print the CPU flag (e.g. '-mcpu=970')."
    echo "  -O: (for gcc) print the optimization flag (e.g. '-O2')."
    echo "  --arch-check foo-1.0: print the architecture of foo-1.0's binaries."
    echo "  --linker-check foo-1.0: print the linked libraries for foo-1.0."
    echo "  --url-exists http://...: fail if the url is a 404."
    echo "  --install-binpkg foo-1.0: download and unpack a binary tarball into /opt."
    echo "  --unpack-dist foo-1.0: download and unpack a source tarball into /tmp."
    echo "  --unpack-tarball-check-md5 http://... /dest/dir:"
    echo "      download, unpack and verify a tarball into /dest/dir."
    echo
    echo "Influential environmental variables:"
    echo "  LEOPARDSH_MIRROR: the root URL to fetch all files from."
    echo "      Default value: LEOPARDSH_MIRROR=https://leopard.sh"
    echo "      Note: both 'https://...' and 'file:///...' are supported."
    echo "      Note: http is faster than https, try:"
    echo "            'export LEOPARDSH_MIRROR=http://leopard.sh'"
    echo "            (MD5 sums will still be verified when using http)."
    echo "  LEOPARDSH_VERBOSE: same effect as using --verbose."
    echo "  LEOPARDSH_FORCE_BUILD_PKGSPEC: build the package from source."
    echo "    e.g.: LEOPARDSH_FORCE_BUILD_PKGSPEC=foo-1.0 leopard.sh foo-1.0"
    echo "  LEOPARDSH_FORCE_BUILD_ALL: build the package and all dependencies from source."
    echo "  LEOPARDSH_RUN_TESTS: run 'make check' after building a package from source."
    echo "  LEOPARDSH_RUN_LONG_TESTS: run tests which are known to take a long time."
    echo "  LEOPARDSH_RUN_BROKEN_TESTS: run tests which are known to fail."
    echo "  LEOPARDSH_MIRROR_NO_HTTP: set to indicate your mirror redirects HTTP traffic HTTPS."
    echo "  LEOPARDSH_MIRROR_NO_HEAD: set to indicate your mirror does not allow HEAD requests."
    exit 0
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
        echo leopard.$cpu_name
    elif test "$1" = "--bits" ; then
        if test "$cpu_name" = "g5" ; then
            echo 64
        else
            echo 32
        fi
    fi

    exit 0
fi


# arch check:

if test "$op" = "arch-check" ; then
    shift 1
    if test -z "$1" ; then
        echo -e "${COLOR_RED}Error${COLOR_NONE}: arch-check which package?" >&2
        echo "e.g. leopard.sh --arch-check tar-1.34" >&2
        exit 1
    fi

    pkgspec="$1"

    if echo $pkgspec | grep -q '\.ppc64' ; then
        ppc64=1
    fi

    COLOR_GREEN="\\\e[32;1m"
    COLOR_YELLOW="\\\e[33;1m"
    COLOR_CYAN="\\\e[36;1m"
    COLOR_NONE="\\\e[0m"

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
        echo -e "${COLOR_RED}Error${COLOR_NONE}: linker-check which package?" >&2
        echo "e.g. leopard.sh --linker-check tar-1.34" >&2
        exit 1
    fi

    pkgspec="$1"

    COLOR_GREEN="\\\e[32;1m"
    COLOR_YELLOW="\\\e[33;1m"
    COLOR_CYAN="\\\e[36;1m"
    COLOR_NONE="\\\e[0m"

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


# glass-dock:

if test "$op" = "glass-dock" ; then
    shift 1
    if test -z "$1" ; then
        onoff=$(defaults read com.apple.dock no-glass)
        if test "$onoff" = "0" ; then
            echo "The glass dock effect is currently on."
            exit 0
        elif test "$onoff" = "1" ; then
            echo "The glass dock effect is currently off."
            exit 0
        else
            exit 1
        fi
    fi

    onoff="$1"

    if test "$onoff" = "on" ; then
        defaults write com.apple.dock no-glass -boolean NO
        killall Dock
    elif test "$onoff" = "off" ; then
        defaults write com.apple.dock no-glass -boolean YES
        killall Dock
    else
        echo -e "${COLOR_RED}Error${COLOR_NONE}: turn the Dock's \"glass\" effect on or off?" >&2
        echo "e.g. leopard.sh --glass-dock off" >&2
        exit 1
    fi

    exit 0 
fi


# spotlight:

if test "$op" = "spotlight" ; then
    shift 1
    onoff="$1"

    if test "$onoff" = "on" ; then
        set -x
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
        sudo launchctl load -w /System/Library/LaunchAgents/com.apple.Spotlight.plist
        { set +x; } 2>/dev/null
    elif test "$onoff" = "off" ; then
        set -x
        sudo launchctl unload -w /System/Library/LaunchAgents/com.apple.Spotlight.plist
        sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
        { set +x; } 2>/dev/null
        echo "Note: if the above commands emitted errors, you may need to restart your Mac for this change to take effect."
    else
        echo -e "${COLOR_RED}Error${COLOR_NONE}: turn Spotlight on or off?" >&2
        echo "e.g. leopard.sh --spotlight off" >&2
        exit 1
    fi

    exit 0 
fi
