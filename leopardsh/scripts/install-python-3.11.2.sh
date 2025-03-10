#!/bin/bash
# based on templates/build-from-source.sh v6

# Install python on OS X Leopard / PowerPC.

# FIXME: tkinter still isn't working.

package=python
version=3.11.2
upstream=https://www.python.org/ftp/python/$version/Python-$version.tgz
description="An interpreted, interactive, object-oriented programming language"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: python doesn't like libressl.
#   checking for openssl/ssl.h in /opt/libressl-3.4.2... yes
#   checking whether compiling and linking against OpenSSL works... yes
#   checking for --with-openssl-rpath... 
#   checking whether OpenSSL provides required ssl module APIs... no
#   checking whether OpenSSL provides required hashlib module APIs... no
# https://github.com/kisslinux/repo/issues/263
# https://peps.python.org/pep-0644/#libressl
# https://twitter.com/christianheimes/status/953991201660788736?lang=en

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

if ! test -e /opt/gcc-4.9.4 ; then
    leopard.sh gcc-libs-4.9.4
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

if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Many thanks to the MacPorts team!
for triple in \
    "-p0 patch-setup.py.diff 0036648697b52bf335cf3b953a06292f" \
    "-p0 patch-Lib-cgi.py.diff 46927f93e99c7226553627e1ab8a4e2a" \
    "-p0 patch-configure.diff 05d083c703c411a400f994bcd1b193c1" \
    "-p0 patch-Lib-ctypes-macholib-dyld.py.diff 7590aab5132d3b70b4a7d1980c4d3a56" \
    "-p0 sysconfig.py.patch c1f459a3c809af606f81378caa73c45d" \
    "-p0 static_assert.patch d456ae0da65b11fbf3f7ab33c6bf3bcc" \
    "-p0 patch-no-copyfile-on-Tiger.diff 26274b5a66846bffaf35b0ea951afde8" \
    "-p0 patch-threadid-older-systems.diff 02c3f4bac14fef79e7ecae1af45a1f72" \
; do
    plevel=$(echo $triple | cut -d' ' -f1)
    pfile=$(echo $triple | cut -d' ' -f2)
    sum=$(echo $triple | cut -d' ' -f3)
    url=https://raw.githubusercontent.com/macports/macports-ports/master/lang/python311/files/$pfile
    curl --fail --silent --show-error --location --remote-name $url
    test "$(md5 -q $pfile)" = "$sum"
    patch $plevel < $pfile
done

CC=gcc-4.9

CFLAGS=$(leopard.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# Thanks to https://trac.macports.org/ticket/66483
LDFLAGS="$LDFLAGS -Wl,-read_only_relocs,suppress"

# Note: --enable-optimizations is unavailable for gcc-4.9:
#   gcc-4.9: error: unrecognized command line option '-fprofile-instr-generate'

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --enable-shared \
    --with-openssl=/opt/openssl-1.1.1t$ppc64 \
    --with-system-ffi \
    --with-system-expat \
    --with-computed-gotos \
    CPPFLAGS="$CPPFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CFLAGS="$CFLAGS" \
    OPT="$CFLAGS" \
    CC="$CC" \
    LIBLZMA_CFLAGS="-I/opt/xz-5.2.5$ppc64/include -L/opt/xz-5.2.5$ppc64/lib" \
    LIBLZMA_LIBS="-llzma" \
    LIBSQLITE3_CFLAGS="-I/opt/sqlite3-3.40.1$ppc64/include -L/opt/sqlite3-3.40.1$ppc64/lib" \
    LIBSQLITE3_LIBS="-lsqlite3" \
    GDBM_CFLAGS="-I/opt/gdbm-1.23$ppc64/include -L/opt/gdbm-1.23$ppc64/lib" \
    GDBM_LIBS="-lgdbm" \
    TCLTK_CFLAGS="-I/opt/tcl-8.6.12$ppc64/include -I/opt/tk-8.6.12$ppc64/include -L/opt/tcl-8.6.12$ppc64/lib -L/opt/tk-8.6.12$ppc64/lib" \
    TCLTK_LIBS="-ltcl8.6 -ltk8.6"

    # --with-lto=full \
    # --with-system-libmpdec \

# Test the openssl integration via the REPL:
#  import ssl ; print(ssl.OPENSSL_VERSION)
#  import urllib.request ; print(urllib.request.urlopen("https://leopard.sh").read())

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

make install

scripts_dir=/opt/$pkgspec/share/leopard.sh/$pkgspec
mkdir -p $scripts_dir

cat > $scripts_dir/test-ssl.py << 'EOF'
#!/usr/bin/env python3
import urllib.request
print(urllib.request.urlopen("https://leopard.sh").read())
EOF
chmod +x $scripts_dir/test-ssl.py

cat > $scripts_dir/test-tkinter.py << 'EOF'
#!/usr/bin/env python3
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
