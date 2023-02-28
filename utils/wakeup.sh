#!/bin/bash

# send a wake-on-lan packet to the given hostname.

set -e

if test -z "$1" ; then
    echo "usage: $0 <hostname>" >&2
    exit 1
fi

hostname=$1

ip=$( host $hostname | head -n1 | awk '{print $NF}' )
echo "$hostname has IP address $ip"

mac=$( arp $ip | grep -e ':.*:.*:.*:.*:' | perl -pe 's/.* (.*?:.*:.*:.*:.*:.*?) .*/\1/' )
if test -z "$mac" ; then
    echo "Error: unable to determine MAC address of $hostname." >&2
    echo "(Apparently, ARP entries are removed after four hours?)" >&2
    exit 1
fi
echo "$ip has MAC address $mac"

set -x
wakeonlan $mac
