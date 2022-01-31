#!/bin/bash

set -e -o pipefail -x

rm -rf /opt/*
rm -rf /usr/local/*

export LEOPARDSH_MIRROR=file://$HOME/leopard.sh
for pkg in $(cat ~/leopard.sh/no-deps.txt) ; do
    leopard.sh $pkg
done
