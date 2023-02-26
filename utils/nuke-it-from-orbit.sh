#!/bin/bash

set -e -x

if test -e /opt/local ; then
    echo "Nope!  Not taking the risk of wiping out your MacPorts installation." >&2
    exit 1
fi

cd

rm -rf \
    ~/Desktop/leopard.sh \
    ~/Desktop/leopardsh \
    ~/Desktop/tigersh \
    ~/bin/leopard.sh \
    ~/bin/tiger.sh \
    ~/bin/make-leopardsh-binpkg.sh \
    ~/bin/make-tigersh-binpkg.sh \
    ~/bin/make-binpkg.sh \
    ~/bin/rebuild-leopardsh-stales.sh \
    ~/bin/rebuild-tigersh-stales.sh \
    ~/bin/rebuild-stales.sh \
    ~/bin/rebuild-leopardsh-all.sh \
    ~/bin/rebuild-tigersh-all.sh \

if test "$1" = "--really-nuke-it" ; then
    sudo rm -rf /opt /usr/local
fi
