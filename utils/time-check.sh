#!/bin/bash

hosts=${1:-"imacg5 imacg52 emac3 emac2 pbookg42 graphite ibookg3"}

uphosts=""
for host in $hosts ; do
    if ping -o -t 1 $host.local >/dev/null 2>&1 ; then
        uphosts="$uphosts $host"
    fi
done

echo -e "`date` on `hostname -s`"

for host in $uphosts ; do
    echo -e "`ssh $host date` on $host"
done
