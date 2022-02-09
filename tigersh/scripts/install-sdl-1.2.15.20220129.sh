#!/bin/bash
# based on templates/template.sh v3

# Install SDL 1.2 on OS X Tiger / PowerPC.

package=sdl
version=1.2.15.20220129

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    # srcmirror=https://www.libsdl.org/release
    # tarball=SDL-$version.tar.gz
    srcmirror=https://github.com/libsdl-org/SDL-1.2/archive
    tarball=707e2cc25904bd4ea7ca94f45632e02d7dbee14c.tar.gz

    if ! test -e ~/Downloads/SDL-1.2-$tarball ; then
        cd ~/Downloads
        # curl -#fLO $srcmirror/$tarball
        curl -#fL $srcmirror/$tarball > SDL-1.2-707e2cc25904bd4ea7ca94f45632e02d7dbee14c.tar.gz
    fi

    test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 61bdc303ab6f69cca619173e4d74fe5c

    cd /tmp
    rm -rf SDL-1.2-main

    tar xzf ~/Downloads/SDL-1.2-$tarball

    cd SDL-1.2-main

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    for f in configure ; do
        if test -n "$ppc64" ; then
            perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"-m64 $(tiger.sh -mcpu -O)\"/g" $f
            export LDFLAGS=-m64
        else
            perl -pi -e "s/CFLAGS=\"-g -O2\"/CFLAGS=\"$(tiger.sh -m32 -mcpu -O)\"/g" $f
        fi
    done

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
        --disable-directx

    make $(tiger.sh -j) V=1

    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi

    make install

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi
