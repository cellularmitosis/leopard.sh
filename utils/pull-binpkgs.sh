#!/bin/bash

set -e

if test -z "$1" ; then
    echo "Usage: $0 <host>" >&2
    exit 1
fi

host=$1
shift 1

ssh $host mkdir -p /Users/macuser/Desktop/leopard.sh/binpkgs /Users/macuser/Desktop/tiger.sh/binpkgs
rsync -ai --update $host:/Users/macuser/Desktop/leopard.sh/binpkgs/ ~/leopard.sh/binpkgs
rsync -ai --update $host:/Users/macuser/Desktop/tiger.sh/binpkgs/ ~/leopard.sh/binpkgs
ssh $host rm -f '/Users/macuser/Desktop/*.sh/binpkgs/*'
