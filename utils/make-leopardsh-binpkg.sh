#!/bin/bash

set -e -x

pkg=$1
cd /opt
binpkg=$pkg.$(leopard.sh --os.cpu).tar.gz
mkdir -p ~/binpkgs
tar czf ~/binpkgs/$binpkg $pkg
