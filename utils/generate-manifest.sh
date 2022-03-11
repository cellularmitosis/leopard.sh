#!/bin/bash

set -e -o pipefail

rm -f md5s.manifest md5s.manifest.gz
for d in binpkgs dist dist/orig leopardsh/scripts tigersh/scripts leopardsh/config.cache tigersh/config.cache ; do
    cat $d/md5s.manifest | sed "s|^|$d/|" >> md5s.manifest
done

cat md5s.manifest | gzip -9 > md5s.manifest.gz
