#!/bin/bash

# sleep all of the hosts in the build farm (the "cat farm").

set -e

mkdir -p ~/.ssh/sockets

hosts=${1:-"imacg5 imacg52 emac2 emac3 pbookg4 pbookg42 graphite ibookg3 imacg3"}

uphosts=""
echo "👉 ping"
# make two passes, because sometimes the .local hosts resolve after a ping.
for host in $hosts ; do
    ping -o -t 1 $host.local >/dev/null 2>&1 || true
done
for host in $hosts ; do
    if ping -o -t 1 $host.local >/dev/null 2>&1 ; then
        uphosts="$uphosts $host"
        echo " ✅ $host is up"
    else
        echo " ❌ $host is down"
    fi
done

cd ~/catfarm

echo
echo "😴 sleep"
for host in $uphosts ; do
    echo "  🖥  $host"
    ssh $host '~/bin/sleep.sh' \& 
done
