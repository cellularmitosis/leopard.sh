#!/bin/bash

set -e
set -x

version=9.5.9-racket-20230127

rm -rf ChezScheme chezscheme-$version chezscheme-$version.tar.gz
git clone \
    --depth=1 \
    --recurse-submodules \
    --shallow-submodules \
    https://github.com/racket/ChezScheme.git
cd ChezScheme
for d in . boot/pb lz4 nanopass stex zlib zuo ; do
    rm -rf $d/.git* $d/.circleci* $d/.travis*
done
cd ..
mv ChezScheme chezscheme-$version
tar c chezscheme-$version | gzip -9 > chezscheme-$version.tar.gz
