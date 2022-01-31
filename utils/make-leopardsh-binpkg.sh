#!/bin/bash

set -e -x

pkg=$1
cd /opt
binpkg=$pkg.$(leopard.sh --os.cpu).tar.gz
tar czf /tmp/$binpkg $pkg
scp /tmp/$binpkg ssl:/var/www/html/leopardsh/
