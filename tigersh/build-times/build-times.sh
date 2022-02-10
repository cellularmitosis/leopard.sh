#!/bin/bash

set -e -o pipefail

cd ~/tigersh/binpkgs
for f in *.tiger.*.tar.gz ; do
    pkgspec=$(echo $f | sed 's/\.tiger.*$//')
    os_cpu=$(echo $f | sed 's/.*\.\(tiger.*\).tar.gz$/\1/')

    # note: some old binpkgs don't have build times in the logs,
    # so we tollerate failure here.
    set +o pipefail
    seconds=$(\
        tar -xzOf $f $pkgspec/share/tiger.sh/$pkgspec/install-$pkgspec.sh.log.gz \
            | gunzip \
            | grep ' real .* user .* sys' \
            | tail -n1 \
            | awk '{print $1}' \
            | sed 's/\..*$//'
    )
    set -o pipefail
    if test -z "$seconds" ; then
        seconds=0
    fi

    echo $seconds $pkgspec $os_cpu
done
cd - >/dev/null
