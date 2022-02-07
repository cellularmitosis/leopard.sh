#!/bin/bash

set -e -x

rsync -av tiger.sh \
    install*.sh \
    packages.txt \
    ldd.sh \
    make-tigersh-bottle.sh \
    reinstall-tigersh.sh \
    ssl:/var/www/html/tigersh/
