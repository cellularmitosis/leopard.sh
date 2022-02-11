#!/bin/bash
# based on templates/install-foo-1.0.sh v4

# Install SDL 1.2 on OS X Leopard / PowerPC.

package=sdl
version=1.2.15.20220129

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
    # srcmirror=https://www.libsdl.org/release
    # tarball=SDL-$version.tar.gz
    srcmirror=https://github.com/libsdl-org/SDL-1.2/archive
    commithash=707e2cc25904bd4ea7ca94f45632e02d7dbee14c
    tarball=$commithash.tar.gz

    if ! test -e ~/Downloads/SDL-1.2-$tarball ; then
        cd ~/Downloads
        # curl -#fLO $srcmirror/$tarball
        curl -#fL $srcmirror/$tarball > SDL-1.2-$commithash.tar.gz
    fi
    tarball=SDL-1.2-$commithash.tar.gz

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 61bdc303ab6f69cca619173e4d74fe5c

    cd /tmp
    rm -rf SDL-1.2-main

    tar xzf ~/Downloads/$tarball

    cd SDL-1.2-main

    cat /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache > config.cache

    # Note: we have to do a bit of flag hackery here to avoid the dylib reporting the wrong arch:
    #   Non-fat file: lib/libSDL-1.2.0.dylib is architecture: ppc
    CC="gcc $(leopard.sh -mcpu -O)"

    CFLAGS=$(leopard.sh -mcpu -O)
    if test -n "$ppc64" ; then
        CFLAGS="-m64 $CFLAGS"
        LDFLAGS="-m64 $LDFLAGS"
        CC="$CC -m64"
    fi

    ./configure -C --prefix=/opt/$pkgspec \
        --disable-oss \
        --disable-alsa \
        --disable-esd \
        --disable-sndio \
        --disable-pulseaudio \
        --disable-nas \
        --disable-video-photon \
        --disable-video-fbcon \
        --disable-video-directfb \
        --disable-video-ps2gs \
        --disable-video-ps3 \
        --disable-video-svga \
        --disable-video-vgl \
        --disable-video-wscons \
        --disable-input-tslib \
        --disable-video-grop \
        --disable-directx \
        CFLAGS="$CFLAGS" \
        LDFLAGS="$LDFLAGS" \
        CC="$CC"

    make $(leopard.sh -j) V=1

    if test -n "$LEOPARDSH_RUN_TESTS" ; then
        make check
    fi

    make install

    leopard.sh --linker-check $pkgspec
    leopard.sh --arch-check $pkgspec $ppc64

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi
