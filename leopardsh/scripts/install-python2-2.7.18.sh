#!/bin/bash
# based on templates/build-from-source.sh v6

# Install python2 on OS X Leopard / PowerPC.

package=python2
version=2.7.18
upstream=https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    readline-8.2$ppc64 \
    openssl-1.1.1t$ppc64 \
    xz-5.2.5$ppc64 \
    libffi-3.4.2$ppc64 \
    expat-2.5.0$ppc64 \
    sqlite3-3.40.1$ppc64 \
    gdbm-1.23$ppc64 \
    tcl-8.6.12$ppc64 \
    tk-8.6.12$ppc64
do
    if ! test -e /opt/$dep ; then
        leopard.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done

# if ! test -e /opt/gcc-4.9.4 ; then
#     leopard.sh gcc-libs-4.9.4
# fi

if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
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

# if ! which -s gcc-4.9 ; then
#     leopard.sh gcc-4.9.4
# fi


echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CC="gcc-4.2"

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# On leopard/G5/ppc32 only, I get this error when linking against tk:
# dyld: Library not loaded: /usr/X11/lib/libX11.6.dylib
#   Referenced from: /opt/tk-8.6.12/lib/libtk8.6.dylib
#   Reason: Incompatible library version: libtk8.6.dylib requires version 10.0.0 or later, but libX11.6.dylib provides version 9.0.0
if test "$(leopard.sh --cpu)" = "g5" ; then
    /usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
        --enable-shared \
        --with-system-ffi \
        --with-system-expat \
        --with-computed-gotos \
        --with-tcltk-includes="-I/opt/tcl-8.6.12$ppc64/include" \
        --with-tcltk-libs="-L/opt/tcl-8.6.12$ppc64/libs" \
        CPPFLAGS="$CPPFLAGS" \
        LDFLAGS="$LDFLAGS" \
        CFLAGS="$CFLAGS" \
        OPT="$CFLAGS" \
        CC="$CC" \
        LIBS="-lreadline -lssl -llzma -lffi -lexpat -lsqlite3 -lgdbm -ltcl8.6"
else
    /usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
        --enable-shared \
        --with-system-ffi \
        --with-system-expat \
        --with-computed-gotos \
        --with-tcltk-includes="-I/opt/tcl-8.6.12$ppc64/include -I/opt/tk-8.6.12$pcc64/include" \
        --with-tcltk-libs="-L/opt/tcl-8.6.12$ppc64/libs -L/opt/tk-8.6.12$pcc64/libs" \
        CPPFLAGS="$CPPFLAGS" \
        LDFLAGS="$LDFLAGS" \
        CFLAGS="$CFLAGS" \
        OPT="$CFLAGS" \
        CC="$CC" \
        LIBS="-lreadline -lssl -llzma -lffi -lexpat -lsqlite3 -lgdbm -ltcl8.6 -ltk8.6"
fi

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

make install
cd /opt/$pkgspec
mv bin/idle bin/idle2
mv bin/pydoc bin/pydoc2
rm bin/python bin/python-config bin/smtpd.py share/man/man1/python.1
cd - >/dev/null

/opt/$pkgspec/bin/python2.7 -m ensurepip --upgrade
/opt/$pkgspec/bin/pip install --upgrade pip

scripts_dir=/opt/$pkgspec/share/leopard.sh/$pkgspec
mkdir -p $scripts_dir

cat > $scripts_dir/test-ssl.py << 'EOF'
#!/usr/bin/env python2
import urllib2
contents = urllib2.urlopen("https://leopard.sh").read()
EOF
chmod +x $scripts_dir/test-ssl.py

cat > $scripts_dir/test-tkinter.py << 'EOF'
#!/usr/bin/env python2
# thanks to https://www.geeksforgeeks.org/hello-world-in-tkinter/
from tkinter import *
root = Tk()
a = Label(root, text ="Hello World")
a.pack()
root.mainloop()
EOF
chmod +x $scripts_dir/test-tkinter.py

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
