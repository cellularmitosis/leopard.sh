#!/bin/bash

# tiger.sh: package manager for PowerPC Macs running OS X Tiger (10.4).

set -e

orig_pwd=$PWD

# Note: for offline use or to run you own local fork, export e.g.
#   TIGERSH_MIRROR=file:///Users/foo/github/cellularmitosis/leopard.sh
TIGERSH_MIRROR=${TIGERSH_MIRROR:-http://leopard.sh}
export TIGERSH_MIRROR

# no alarms and no surprises, please.
export PATH="/opt/tigersh-deps-0.1/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

COLOR_GREEN="\\\e[32;1m"
COLOR_YELLOW="\\\e[33;1m"
COLOR_CYAN="\\\e[36;1m"
COLOR_NONE="\\\e[0m"

osversion=$(sw_vers -productVersion | awk '{print $NF}')
if ! test "${osversion:0:4}" = "10.4" ; then
    echo "Sorry, this script was written for OS X Tiger :(" >&2
    exit 1
fi

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
    echo tiger.$cpu_name
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

for d in /opt /usr/local /usr/local/bin /usr/local/sbin ; do
    if ! test -e $d ; then
        echo "Creating $d." >&2
        sudo mkdir $d
        sudo chgrp admin $d
        sudo chmod g+w $d
    fi

    if ! mktemp $d/write-check.XXX >/dev/null ; then
        echo "Notice: can't write to $d." >&2
        echo "Running 'sudo chgrp admin $d && sudo chmod g+w /opt'." >&2
        sudo chgrp admin $d
        sudo chmod g+w $d
    else
        rm -f $d/write-check.*
    fi

    if ! mktemp $d/write-check.XXX >/dev/null ; then
        echo "Error: can't write to $d." >&2
        echo "Check that you are in the 'admin' group (run 'groups')." >&2
        exit 1
    else
        rm -f $d/write-check.*
    fi
done

mkdir -p ~/Downloads

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
        && cat $fifo | md5 > /tmp/$binpkg.localmd5_ \
        && mv /tmp/$binpkg.localmd5_ /tmp/$binpkg.localmd5
    ) &

    while ! test -e $fifo ; do sleep 0.1 ; done

    binpkg_url=$TIGERSH_MIRROR/binpkgs/$binpkg
    # At this point we are still using /usr/bin/curl, so no https for you!
    binpkg_url=$(echo "$binpkg_url" | sed 's|^https:|^http:|')
    size=$(curl --fail --silent --show-error --head --insecure $binpkg_url \
        | grep -i '^content-length:' \
        | awk '{print $NF}' \
        | sed "s/$(printf '\r')//"
    )

    cd /opt
    curl --fail --silent --show-error --insecure $binpkg_url \
        | pv --force --size $size \
        | tee $fifo \
        | gunzip \
        | tar x

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
    echo "    -> This is where I need your help, human! <-" >&2
    echo >&2
    echo "Please visit https://leopard.sh/md5 in a modern browser (or by scanning the" >&2
    echo "above QR code on your smartphone) and verify the following MD5 sums:" >&2
    echo >&2
    echo "    $(basename \"$0\"): $(cd "$orig_pwd" && md5 -q "$0")" >&2
    echo >&2
    echo "    $binpkg: $(cat /tmp/$binpkg.localmd5)" >&2
    echo >&2

    read -n 1 -p "Do the MD5 sums match? [Y/n]: " answer
    while true ; do
        if test "$answer" = "" ; then
            break
        elif test "$answer" = "y" -o "$answer" = "Y" ; then
            echo >&2
            break
        elif test "$answer" = "n" -o "$answer" = "N" ; then
            echo >&2
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
            echo >&2
            read -n 1 -r -p "Please type 'y', 'n' or hit ENTER (same as 'y') " answer
        fi
    done

    rm /opt/$deps_pkgspec/INCOMPLETE_INSTALLATION
fi

echo "Running 'sudo mv \"$0\" /usr/local/bin/'." >&2
sudo mv "$0" /usr/local/bin/

if ! echo $PATH | tr ':' '\n' | egrep '^/usr/local/bin/?$' ; then
    echo "Adding /usr/local/bin to your \$PATH." >&2
    for f in ~/.bashrc ~/.bash_profile ~/.profile ; do
        if test -e $f ; then
            echo >> $f
            echo "# Added by tiger.sh:" >> $f
            echo "export PATH=\"/usr/local/bin:/usr/local/sbin:\$PATH\"" >> $f
        fi
    done
    echo >&2
    echo "Note: this script has modified your \$PATH to include /usr/local/bin, but" >&2
    echo "that change won't take effect until you open a new Terminal.app window." >&2
    echo >&2
fi

opt_config_cache=/opt/tiger.sh/share/tiger.sh/config.cache
mkdir -p $opt_config_cache
if ! test -e $opt_config_cache/tiger.cache ; then
    echo "Fetching configure cache." >&2
    cd $opt_config_cache
    curl --fail --silent --show-error --location --remote-name $TIGERSH_MIRROR/tigersh/config.cache/tiger.cache
fi

if test "$1" = "--setup" ; then
    exit 0
fi


# url exists:

if test "$1" = "--url-exists" ; then
    shift 1
    if test -z "$1" ; then
        echo "Error: check which url?" >&2
        echo "e.g. tiger.sh --url-exists http://example.com" >&2
        exit 1
    fi
    url="$1"
    curl --fail --silent --show-error -I "$url" >/dev/null 2>&1
    exit $?
fi


# install binpkg:

FIXME wrap up this refactor

tiger.sh --unpack-tarball-check-md5 http://leopard.sh/dist/gzip-1.11.tar.gz /tmp/gzip-1.11.tar.gz.XXXX
tiger.sh --unpack-tarball-check-md5 http://leopard.sh/binpkgs/gzip-1.11.tiger.g3.tar.gz /opt

tiger.sh --install-binpkg gzip-1.11
tiger.sh --unpack-distfile gzip-1.11.tar.gz /tmp/gzip-1.11.tar.gz.XXXX

if test "$1" = "--install-binpkg" ; then
    shift 1

    if test -z "$1" ; then
        echo "Error: install which binpkg?" >&2
        echo "e.g. tiger.sh --install-binpkg gzip-1.11" >&2
        exit 1
    fi

    pkgspec="$1"
    binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
    binpkg_url=$TIGERSH_MIRROR/binpkgs/$binpkg

    echo "Unpacking $binpkg at /opt/$pkgspec"

    fifo=/tmp/$binpkg.fifo
    rm -f $fifo
    ( mkfifo $fifo \
        && cat $fifo | md5 > /tmp/$binpkg.localmd5_ \
        && mv /tmp/$binpkg.localmd5_ /tmp/$binpkg.localmd5
    ) &

    while ! test -e $fifo ; do sleep 0.1 ; done

    size=$(curl --fail --silent --show-error --head $binpkg_url \
        | grep -i '^content-length:' \
        | awk '{print $NF}' \
        | sed "s/$(printf '\r')//"
    )

    cd /tmp
    curl --fail --silent --show-error --location --remote-name $binpkg_url.md5

    cd /opt
    curl --fail --silent --show-error $binpkg_url \
        | pv --force --size $size \
        | tee $fifo \
        | gunzip \
        | tar x

    while ! test -e /tmp/$binpkg.localmd5 ; do sleep 0.1 ; done

    rm $fifo

    test "$(cat /tmp/$binpkg.localmd5)" = "$(cat /tmp/$binpkg.md5)"
    exit $?
fi



if test "$1" = "--install-binpkg" ; then
    shift 1

    tiger.sh --unpack-tarball-check-md5 $url /opt
fi


# unpack a distfile into /tmp:

if test "$1" = "--unpack-distfile" ; then
    shift 1

    if test -z "$1" ; then
        echo "Error: unpack which distfile?" >&2
        echo "e.g. tiger.sh --unpack-distfile gzip-1.11.tar.gz" >&2
        exit 1
    fi
    distfile="$1"
    shift 1

    url=$TIGERSH_MIRROR/dist/$distfile
    tiger.sh --unpack-tarball-check-md5 $url /tmp
    exit $?
fi


# unpack a tarball and verify its MD5 sum:

if test "$1" = "--unpack-tarball-check-md5" ; then
    shift 1

    if test -z "$1" ; then
        echo "Error: unpack which tarball url?" >&2
        echo "e.g. tiger.sh --unpack-tarball-check-md5 http://leopard.sh/dist/gzip-1.11.tar.gz /tmp" >&2
        echo "e.g. tiger.sh --unpack-tarball-check-md5 http://leopard.sh/binpkgs/gzip-1.11.tiger.g3.tar.gz /opt" >&2
        exit 1
    fi
    url="$1"
    shift 1

    if test -z "$1" ; then
        echo "Error: unpack tarball where?" >&2
        echo "e.g. tiger.sh --unpack-tarball-check-md5 http://leopard.sh/dist/gzip-1.11.tar.gz /tmp" >&2
        echo "e.g. tiger.sh --unpack-tarball-check-md5 http://leopard.sh/binpkgs/gzip-1.11.tiger.g3.tar.gz /opt" >&2
        exit 1
    fi
    dest="$2"
    shift 1

    tmp=$(mktemp -u /tmp/tarball.XXXX)
    fifo=$tmp.fifo
    rm -f $fifo
    ( mkfifo $fifo \
        && cat $fifo | md5 > $tmp.localmd5_ \
        && mv $tmp.localmd5_ $tmp.localmd5
    ) &

    while ! test -e $fifo ; do sleep 0.1 ; done

    size=$(curl --fail --silent --show-error --head $url \
        | grep -i '^content-length:' \
        | awk '{print $NF}' \
        | sed "s/$(printf '\r')//"
    )

    cd /tmp
    curl --fail --silent --show-error --location --remote-name $url.md5

    cd /tmp
    curl --fail --silent --show-error $url \
        | pv --force --size $size \
        | tee $fifo \
        | gunzip \
        | tar x

    while ! test -e $tmp.localmd5 ; do sleep 0.1 ; done

    rm -f $fifo $tmp.localmd5 $tmp.md5

    test "$(cat $tmp.localmd5)" = "$(cat $tmp.md5)"
    exit $?
fi


# arch check:

if test "$1" = "--arch-check" ; then
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

if test "$1" = "--linker-check" ; then
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


# list:

if test -z "$1" ; then
    echo "Available packages:" >&2
    cd /tmp
    curl --fail --silent --show-error --location --remote-name $TIGERSH_MIRROR/tigersh/packages.txt
    if test "$cpu_name" = "g5" ; then
        curl --fail --silent --show-error --location --remote-name $TIGERSH_MIRROR/tigersh/packages.ppc64.txt
        cat packages.txt packages.ppc64.txt | sort
    else
        cat packages.txt
    fi
    exit 0
fi


# install:

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
echo "Installing $pkgspec" >&2
echo -n -e "\033]0;tiger.sh $pkgspec (tiger.$cpu_name)\007"
mkdir -p /opt/$pkgspec
touch /opt/$pkgspec/INCOMPLETE_INSTALLATION
script=install-$pkgspec.sh
cd /tmp
curl --fail --silent --show-error --location --remote-name $TIGERSH_MIRROR/tigersh/scripts/$script
chmod +x $script

# unfortunately, tiger's bash doesn't have pipefail.
# thanks to https://stackoverflow.com/a/1221844
fifo=/tmp/.tiger.sh.$script.fifo
rm -f $fifo
mkfifo $fifo
tee /tmp/$script.log < $fifo &
/usr/bin/time nice ./$script > $fifo 2>&1
rm -f $fifo

if ! test -e /opt/$pkgspec/share/tiger.sh/$pkgspec/$script.log.gz ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip /tmp/$script.log
    mv /tmp/$script.log.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi

rm -f /opt/$pkgspec/INCOMPLETE_INSTALLATION
