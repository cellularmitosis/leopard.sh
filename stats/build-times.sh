#!/bin/bash

# generate statistics about how long each package took to build.

set -e -o pipefail

tmp_by_time=$( mktemp /tmp/.build-times.XXXXXX )
tmp_by_pkg=$( mktemp /tmp/.build-times.XXXXXX )

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
                | grep ' real .* user .* sys' \
                | tail -n1 \
                | awk '{print $1}' \
                | sed 's/\..*$//'
        )
        set -o pipefail

        if test -z "$seconds" ; then
            continue
        fi

        echo $seconds $pkgspec $os_cpu >> $tmp_by_time
        echo $pkgspec $os_cpu $seconds >> $tmp_by_pkg

    done
    cd - >/dev/null
done

cat $tmp_by_time \
    | sort -n \
    | column -t \
    > build-times-by-time.txt

cat $tmp_by_pkg \
    | sort \
    | column -t \
    > build-times-by-pkg.txt

rm $tmp_by_pkg
rm $tmp_by_time
