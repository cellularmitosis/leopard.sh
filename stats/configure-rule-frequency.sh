#!/bin/bash

# generate statistics about how commonly configure rules appear across all packages.

set -e -o pipefail

tmp=$(mktemp /tmp/.configure-rule-frequencies.XXXXXX)

for d in ~/leopardsh/binpkgs ~/tigersh/binpkgs ; do
    cd $d
    for f in *.tar.gz ; do

        pkgspec=$( echo $f | sed -E 's/(.*)\.(tiger|leopard).*\.tar\.gz$/\1/' )
        test -n "$pkgspec"

        os_cpu=$( echo $f | sed -E 's/.*(tiger.*|leopard.*)\.tar\.gz$/\1/' )
        test -n "$pkgspec"

        echo processing $pkgspec >&2

        # note: some old binpkgs don't have logs, so we tollerate failure here.
        set +o pipefail
        seconds=$(\
            tar -xzOf $f $pkgspec/share/*.sh/$pkgspec/install-$pkgspec.sh.log.gz \
                | gunzip \
                | ( grep '^checking ' || true ) \
                >> $tmp
        )
        set -o pipefail

    done
    cd - >/dev/null
done

cat $tmp \
    | grep '(cached)' \
    | sort \
    | uniq -c \
    | sort -n \
    > configure-rule-frequency-cached.txt

cat $tmp \
    | grep -v '(cached)' \
    | sort \
    | uniq -c \
    | sort -n \
    > configure-rule-frequency-uncached.txt

rm $tmp
