#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install zstd on OS X Leopard / PowerPC.

package=zstd
version=1.5.1
upstream=https://github.com/facebook/$package/releases/download/v$version/$package-$version.tar.gz

set -e -x -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else

if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    curl -#fLO $srcmirror/$tarball
fi

test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = b97d53547220355907dedec7de9a4f29

cd /tmp
rm -rf $package-$version

tar xzf ~/Downloads/$tarball

cd /tmp/$package-$version

# Fix for '-compatibility_version only allowed with -dynamiclib' error:
perl -pi -e "s/-compatibility_version/-dynamiclib -compatibility_version/" lib/Makefile

for f in Makefile */Makefile */*/Makefile */*.mk ; do
    if test -n "$ppc64" ; then
        perl -pi -e "s/-O3/-m64 $(leopard.sh -mcpu -O)/g" $f
    else
        perl -pi -e "s/-O3/$(leopard.sh -mcpu -O)/g" $f
    fi
done

/usr/bin/time make $(leopard.sh -j) V=1 prefix=/opt/$pkgspec

if test -n "$LEOPARDSH_RUN_BROKEN_TESTS" ; then
    # 'make check' fails to build:
    # cc1: error: unrecognized command line option "-Wvla"
    # cc1: error: unrecognized command line option "-Wc++-compat"
    # cc1: error: unrecognized command line option "-Wno-c++-compat"
    # cc1: error: unrecognized command line option "-Wvla"
    # cc1: error: unrecognized command line option "-Wc++-compat"
    # cc1: error: unrecognized command line option "-Wno-c++-compat"
    # make[1]: *** [datagen] Error 1
    # make: *** [shortest] Error 2

    make check
fi

make prefix=/opt/$pkgspec install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64
