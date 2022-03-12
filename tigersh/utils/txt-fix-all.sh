#!/bin/bash

set -e -x

for i in scripts/old/install-*.sh; do
    if test -L $i ; then
        continue
    fi
    utils/txt-fix.py $i --write
done
