#!/bin/bash

set -e -x

for i in install-*.sh; do
    ./txt-fix.py $i --write
done
