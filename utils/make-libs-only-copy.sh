#!/bin/bash

# Make a copy of just the /libs dir as a separate /opt package.
# Useful for shipping a libraries-only copy of e.g. gcc.

set -e

if test -z "$1" ; then
   echo "Usage: $0 <src_pkgspec> <dest_pkgspec>" >&2
   echo "e.g. $0 gcc-4.9.4 gcc-libs-4.9.4" >&2
fi
src_pkgspec=$1
shift 1

if test -z "$1" ; then
   echo "Usage: $0 <src_pkgspec> <dest_pkgspec>" >&2
   echo "e.g. $0 gcc-4.9.4 gcc-libs-4.9.4" >&2
fi
dest_pkgspec=$1
shift 1

mkdir -p /opt/$dest_pkgspec

if test -e /opt/$src_pkgspec/lib ; then
    cp -rp -v /opt/$src_pkgspec/lib /opt/$dest_pkgspec/
fi

if test -e /opt/$dest_pkgspec/share/tiger.sh ; then
    mkdir -p /opt/$dest_pkgspec/share
    cp -rp /opt/$src_pkgspec/lib/tiger.sh /opt/$dest_pkgspec/share/
fi

if test -e /opt/$dest_pkgspec/share/leopard.sh ; then
    mkdir -p /opt/$dest_pkgspec/share
    cp -rp /opt/$src_pkgspec/lib/leopard.sh /opt/$dest_pkgspec/share/
fi
