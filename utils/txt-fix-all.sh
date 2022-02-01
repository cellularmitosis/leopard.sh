#!/bin/bash

set -e -x

for i in scripts/install-*.sh; do
    utils/txt-fix.py $i --write
done
