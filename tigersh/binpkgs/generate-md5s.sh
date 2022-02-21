#!/bin/bash

set -e

if ! find . -name '*.tar.gz' | grep -q . ; then
    exit 0
fi

for f in *.tar.gz ; do

    if ! test -e $f.md5 ; then
        should_md5=1
    else
        md5_mtime=$(stat -f '%m' $f.md5)
        binpkg_mtime=$(stat -f '%m' $f)
        if test "$md5_mtime" -lt "$binpkg_mtime" ; then
            should_md5=1
        fi
    fi

    if test "$should_md5" = "1" ; then
        echo "Generating $f.md5" >&2
        md5 -q $f > $f.md5
    fi

done
