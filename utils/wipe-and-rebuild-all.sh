#!/bin/bash

set -e -o pipefail -x

rm -rf /opt/*
rm -rf /usr/local/*

export LEOPARDSH_MIRROR=file://$HOME/Desktop/leopard.sh
for pkg in $(cat ~/Desktop/leopard.sh/no-deps.txt) ; do
    leopard.sh $pkg
done
