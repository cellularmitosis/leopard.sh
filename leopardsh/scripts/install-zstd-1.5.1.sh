#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install zstd on OS X Leopard / PowerPC.

package=zstd
version=1.5.1

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://github.com/facebook/$package/releases/download/v$version
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    # Fix for '-compatibility_version only allowed with -dynamiclib' error:
    perl -pi -e "s/-compatibility_version/-dynamiclib -compatibility_version/" lib/Makefile

    for f in Makefile */Makefile */*/Makefile */*.mk ; do
        if test -n "$ppc64" ; then
            perl -pi -e "s/-O3/-m64 $(leopard.sh -mcpu -O)/g" $f
        else
            perl -pi -e "s/-O3/$(leopard.sh -m32 -mcpu -O)/g" $f
        fi
    done

    make $(leopard.sh -j) V=1 prefix=/opt/$pkgspec

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
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi
