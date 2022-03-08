#!/bin/bash

# generate / update md5 sums as needed.

set -e

rm -f md5s.manifest md5s.manifest.gz

tmp=$( mktemp /tmp/md5-files.XXXX )

find * -maxdepth 0 -name '*.*' \
    | grep -v -e '\.md5$' -e 'generate-md5s\.sh$' > $tmp \
    || true

while read f ; do

    unset should_md5
    if ! test -e "$f.md5" ; then
        should_md5=1
    else
        md5_mtime=$(stat -f '%m' "$f.md5")
        binpkg_mtime=$(stat -f '%m' "$f")
        if test "$md5_mtime" -lt "$binpkg_mtime" ; then
            should_md5=1
        fi
    fi

    if test "$should_md5" = "1" ; then
        echo "Generating \"$f.md5\"" >&2
        md5 -q "$f" > "$f.md5"
    fi

done < $tmp

find * -maxdepth 0 -name '*.md5' > $tmp || true

while read f ; do
    echo "$(basename "$f" .md5) $(cat "$f")" >> md5s.manifest
done < $tmp

cat md5s.manifest | gzip -9 > md5s.manifest.gz

rm -f $tmp
