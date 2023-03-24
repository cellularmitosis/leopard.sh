#!/bin/bash
# based on templates/build-from-source.sh v6

# Install GTK+ on OS X Leopard / PowerPC.

package=gtk+
version=1.2.10
upstream=https://download.gnome.org/sources/gtk+/1.2/$package-$version.tar.gz
description="A multi-platform toolkit for creating graphical user interfaces"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

dep=glib-1.2.10$ppc64
if ! test -e /opt/$dep ; then
    leopard.sh $dep
    PATH="/opt/$dep/bin:$PATH"
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS="$(leopard.sh -mcpu -O) $CFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
fi

# Note: --enable-shared doesn't appear to work.
/usr/bin/time \
    env CFLAGS="$CFLAGS -fno-common" \
        ./configure --prefix=/opt/$pkgspec \
            --disable-dependency-tracking \
            --host=powerpc-unknown-bsd \
            --target=powerpc-unknown-bsd \
            --with-glib-prefix=/opt/glib-1.2.10$ppc64

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

make install

# An attempt and making dylibs...
cd gdk
gcc $CFLAGS -dynamiclib \
    -install_name /opt/gtk+-1.2.10/lib/libgdk.1.dylib \
    -compatibility_version 1.2 \
    -current_version 1.2.10 \
    -o ../libgdk.1.2.10.dylib \
    gdk.o gdkcc.o gdkcolor.o gdkcursor.o gdkdnd.o \
    gdkdraw.o gdkevents.o gdkfont.o gdkgc.o gdkglobals.o gdkim.o \
    gdkimage.o gdkinput.o gdkpixmap.o gdkproperty.o gdkrgb.o \
    gdkrectangle.o gdkregion.o gdkselection.o gdkvisual.o gdkwindow.o \
    gdkxid.o gxid_lib.o \
    -L/usr/X11R6/lib -lXext -lX11 \
    -L/opt/glib-1.2.10/lib -lglib
cd -

libname=gdk
cp lib${libname}.1.2.10.dylib /opt/$pkgspec/lib/
cd /opt/$pkgspec/lib
ln -s lib${libname}.1.2.10.dylib lib${libname}.dylib
ln -s lib${libname}.1.2.10.dylib lib${libname}.1.dylib
ln -s lib${libname}.1.2.10.dylib lib${libname}.1.2.dylib
cd -

cd gtk
gcc $CFLAGS -dynamiclib \
    -install_name /opt/gtk+-1.2.10/lib/libgtk.1.dylib \
    -compatibility_version 1.2 \
    -current_version 1.2.10 \
    -o ../libgtk.1.2.10.dylib \
    gtkaccelgroup.o gtkaccellabel.o gtkadjustment.o \
    gtkalignment.o gtkarg.o gtkarrow.o gtkaspectframe.o gtkbin.o \
    gtkbindings.o gtkbbox.o gtkbox.o gtkbutton.o gtkcalendar.o \
    gtkcheckbutton.o gtkcheckmenuitem.o gtkclist.o gtkcolorsel.o \
    gtkcombo.o gtkcontainer.o gtkctree.o gtkcurve.o gtkdata.o \
    gtkdialog.o gtkdnd.o gtkdrawingarea.o gtkeditable.o gtkentry.o \
    gtkeventbox.o gtkfilesel.o gtkfixed.o gtkfontsel.o gtkframe.o \
    gtkgamma.o gtkgc.o gtkhandlebox.o gtkhbbox.o gtkhbox.o \
    gtkhpaned.o gtkhruler.o gtkhscale.o gtkhscrollbar.o \
    gtkhseparator.o gtkimage.o gtkinputdialog.o gtkinvisible.o \
    gtkitem.o gtkitemfactory.o gtklabel.o gtklayout.o gtklist.o \
    gtklistitem.o gtkmain.o gtkmarshal.o gtkmenu.o gtkmenubar.o \
    gtkmenufactory.o gtkmenuitem.o gtkmenushell.o gtkmisc.o \
    gtknotebook.o gtkobject.o gtkoptionmenu.o gtkpacker.o gtkpaned.o \
    gtkpixmap.o gtkplug.o gtkpreview.o gtkprogress.o gtkprogressbar.o \
    gtkradiobutton.o gtkradiomenuitem.o gtkrange.o gtkrc.o gtkruler.o \
    gtkscale.o gtkscrollbar.o gtkscrolledwindow.o gtkselection.o \
    gtkseparator.o gtksignal.o gtksocket.o gtkspinbutton.o gtkstyle.o \
    gtkstatusbar.o gtktable.o gtktearoffmenuitem.o gtktext.o \
    gtkthemes.o gtktipsquery.o gtktogglebutton.o gtktoolbar.o \
    gtktooltips.o gtktree.o gtktreeitem.o gtktypeutils.o gtkvbbox.o \
    gtkvbox.o gtkviewport.o gtkvpaned.o gtkvruler.o gtkvscale.o \
    gtkvscrollbar.o gtkvseparator.o gtkwidget.o gtkwindow.o fnmatch.o \
    -L/usr/X11R6/lib -lXext -lX11 \
    -L/opt/glib-1.2.10/lib -lglib -lgmodule \
    -L/opt/gtk+-1.2.10/lib -lgdk
cd ..

libname=gtk
cp lib${libname}.1.2.10.dylib /opt/$pkgspec/lib/
cd /opt/$pkgspec/lib
ln -s lib${libname}.1.2.10.dylib lib${libname}.dylib
ln -s lib${libname}.1.2.10.dylib lib${libname}.1.dylib
ln -s lib${libname}.1.2.10.dylib lib${libname}.1.2.dylib
cd -


leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
