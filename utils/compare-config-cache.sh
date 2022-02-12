#!/bin/bash

set -e

if test -z "$1" ; then
    echo "Example usage:" >&2
    echo "$0 gzip-1.11 --remote" >&2
    echo "$0 gzip-1.11" >&2
    exit 1
fi

pkgspec=$1
shift 1

if test "$1" = "--remote" ; then
    echo "paste the appropriate command into your remote terminals:"
    echo
    echo "echo > ~/Desktop/tigersh/config.cache/tiger.cache && rm -rf /opt/$pkgspec && TIGERSH_FORCE_BUILD=1 tiger.sh $pkgspec"
    echo
    echo "echo > ~/Desktop/leopardsh/config.cache/leopard.cache && rm -rf /opt/$pkgspec && LEOPARDSH_FORCE_BUILD=1 leopard.sh $pkgspec"
    echo
    exit 0
fi

hosts="imacg5 emac3 emac2 pbookg42 graphite ibookg3"
hosts="imacg5 emac2 graphite ibookg3"

uphosts=""
echo "👉 ping"
for host in $hosts ; do
    if ping -o -t 1 $host.local >/dev/null 2>&1 ; then
        uphosts="$uphosts $host"
        echo " ✅ $host"
    else
        echo " ❌ $host"
    fi
done

# collect the config.cache files:
echo "👉 collecting config.cache files"
d=/tmp/$pkgspec.config.cache
rm -rf $d
mkdir -p $d
cd $d
for host in $uphosts ; do
    echo "  🖥  $host"
    ssh $host cat /tmp/$pkgspec/config.cache | sort > $pkgspec.$host.config.cache
    ssh $host cat /tmp/install-$pkgspec.sh.log > install-$pkgspec.sh.log.$host
done

echo
echo "See /tmp/$pkgspec.config.cache"
