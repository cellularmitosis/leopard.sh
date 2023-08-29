#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install glib on OS X Tiger / PowerPC.

package=glib
version=2.76.4
upstream=https://mirror.umd.edu/gnome/sources/glib/2.76/glib-$version.tar.xz
description="The GLib library of C routines"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/gcc-4.9.4 ; then
    tiger.sh gcc-libs-4.9.4
fi

# 👇 EDIT HERE:
# dep=bar-1.0$ppc64
# if ! test -e /opt/$dep ; then
#     tiger.sh $dep
#     PATH="/opt/$dep/bin:$PATH"
# fi

for dep in \
    gettext-0.20$ppc64 \
    pcre2-10.42$ppc64 \
    libffi-3.4.2$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    # CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    # LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    # PATH="/opt/$dep/bin:$PATH"
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
done
# LIBS="-lbar -lqux"
PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"

# Note: meson ignores pkg-config for libintl.
CPPFLAGS="-I/opt/gettext-0.20/include"
LDFLAGS="-L/opt/gettext-0.20/lib"

# we need macports legacy for posix_memalign.
# dep=macports-legacy-support-20221029$ppc64
# if ! test -e /opt/$dep ; then
#     tiger.sh $dep
# fi
# CPPFLAGS="-I/opt/macports-legacy-support-20221029$ppc64/include/LegacySupport $CPPFLAGS"
# LDFLAGS="-L/opt/macports-legacy-support-20221029$ppc64/lib -lMacportsLegacySupport $LDFLAGS"
# LIBS="-lMacportsLegacySupport $LIBS"

# 👇 EDIT HERE:
# if ! perl -e "use Text::Unidecode" >/dev/null 2>&1 ; then
#     echo no | cpan
#     cpan Text::Unidecode
# fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

# 👇 EDIT HERE:
# if test -z "$ppc64" -a "$(tiger.sh --cpu)" = "g5" ; then
#     # Fails during a 32-bit build on a G5 machine,
#     # so we instead install the g4e binpkg in that case.
#     if tiger.sh --install-binpkg $pkgspec tiger.g4e ; then
#         exit 0
#     fi
# else
#     if tiger.sh --install-binpkg $pkgspec ; then
#         exit 0
#     fi
# fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

# 👇 EDIT HERE:
# if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
#     tiger.sh gcc-4.2
# fi
# CC=gcc-4.2
# CXX=g++-4.2

# 👇 EDIT HERE:
if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
fi
CC=gcc-4.9
CXX=g++-4.9
OBJC=gcc-4.9

# 👇 EDIT HERE:
if ! test -e /opt/ld64-97.17-tigerbrew ; then
    tiger.sh ld64-97.17-tigerbrew
fi
export PATH="/opt/ld64-97.17-tigerbrew/bin:$PATH"
# CC='gcc -B/opt/ld64-97.17-tigerbrew/bin'
# CXX='gxx -B/opt/ld64-97.17-tigerbrew/bin'

# 👇 EDIT HERE:
# if ! type -a pkg-config >/dev/null 2>&1 ; then
#     tiger.sh pkg-config-0.29.2
# fi
# export PATH="/opt/pkg-config-0.29.2/bin:$PATH"

if ! type -a meson >/dev/null 2>&1 ; then
    # tiger.sh meson-1.2.1
    tiger.sh meson-0.64.1
fi

if ! type -a ninja >/dev/null 2>&1 ; then
    tiger.sh ninja-1.11.1
fi

if ! type -a pkg-config >/dev/null 2>&1 ; then
    tiger.sh pkg-config-0.29.2
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# 👇 EDIT HERE:
CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(tiger.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# 👇 EDIT HERE:
# /usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
#     --disable-dependency-tracking \
#     --disable-maintainer-mode \
#     --disable-debug \
#     CFLAGS="$CFLAGS" \
#     CXXFLAGS="$CXXFLAGS" \
#     LDFLAGS="$LDFLAGS" \
    # --with-bar=/opt/bar-1.0$ppc64 \
    # --with-bar-prefix=/opt/bar-1.0$ppc64 \
    # CPPFLAGS="$CPPFLAGS" \
    # LIBS="$LIBS" \
    # CC="$CC" \
    # CXX="$CXX" \
    # PKG_CONFIG=/opt/pkg-config-0.29.2/bin/pkg-config \
    # PKG_CONFIG_PATH="/opt/libfoo-1.0$ppc64/lib/pkgconfig:/opt/libbar-1.0$ppc64/lib/pkgconfig" \

# macports legacy provides posix_memalign.
# patch -p0 << 'EOF'
# --- meson.build.orig	2023-08-27 23:37:55.000000000 -0500
# +++ meson.build	2023-08-27 23:38:15.000000000 -0500
# @@ -744,9 +744,7 @@
#    glib_conf.set('HAVE_ALIGNED_ALLOC', 1)
#  endif
 
# -if host_system != 'windows' and cc.has_function('posix_memalign', prefix: '#include <stdlib.h>')
# -  glib_conf.set('HAVE_POSIX_MEMALIGN', 1)
# -endif
# +glib_conf.set('HAVE_POSIX_MEMALIGN', 1)
 
#  # Check that posix_spawn() is usable; must use header
#  if cc.has_function('posix_spawn', prefix : '#include <spawn.h>')
# EOF

# Many thanks to the MacPorts team!
patchroot=https://raw.githubusercontent.com/macports/macports-ports/master/devel/glib2/files
curl -f $patchroot/patch-gio_gcredentials.c.diff | patch -p0
curl -f $patchroot/patch-gio_gcredentialsprivate.h.diff | patch -p0
curl -f $patchroot/patch-gio_xdgmime_xdgmime.c.diff | patch -p0
curl -f $patchroot/patch-glib2-findfolders-before-SL.diff | patch -p0
curl -f $patchroot/patch-glib_gmem.c.diff | patch -p0
curl -f $patchroot/patch-glib_gspawn.c.diff | patch -p0
curl -f $patchroot/patch-gmodule-gmodule-dl.c.diff | patch -p0
curl -f $patchroot/patch-meson_build-meson_options-appinfo.diff | patch -p0

mkdir build
cd build
CC="$CC" \
OBJC="$OBJC" \
CXX="$CXX" \
CPPFLAGS="$CPPFLAGS" \
LDFLAGS="$LDFLAGS" \
LIBS="$LIBS" \
PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
    meson setup .. --prefix=/opt/$pkgspec --buildtype=release -Dman=false -Dtests=false

sed -i '' -e "s| -O3 | $CFLAGS |" build.ninja
# rpath isn't available until Leopard.
sed -i '' -e "s|@rpath/||" build.ninja

ninja -v
ninja install
cd ..

# Note: no 'make check' available.

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
