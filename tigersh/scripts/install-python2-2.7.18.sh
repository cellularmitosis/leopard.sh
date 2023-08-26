#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install python2 on OS X Tiger / PowerPC.

package=python2
version=2.7.18
upstream=https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

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
    tcl-8.6.12$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done

# tk not available on ppc64 (no 64-bit X11 libs on Tiger).
if test -z "$ppc64" ; then
    for dep in \
        tk-8.6.12
    do
        if ! test -e /opt/$dep ; then
            tiger.sh $dep
        fi
        CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
        LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
        PATH="/opt/$dep/bin:$PATH"
    done
fi

# It seems we need gcc-4.9:
# gcc-4.2 -B/opt/ld64-97.17-tigerbrew/bin -c -fno-strict-aliasing -mcpu=970 -O2 -DNDEBUG -mcpu=970 -O2  -I. -IInclude -I./Include -I/opt/tk-8.6.12/include -I/opt/tcl-8.6.12/include -I/opt/gdbm-1.23/include -I/opt/sqlite3-3.40.1/include -I/opt/expat-2.5.0/include -I/opt/libffi-3.4.2/include -I/opt/xz-5.2.5/include -I/opt/openssl-1.1.1t/include -I/opt/readline-8.2/include   -DPy_BUILD_CORE -o Python/mactoolboxglue.o Python/mactoolboxglue.c
# In file included from /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/DriverServices.h:32,
#                  from /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/CarbonCore.h:125,
#                  from /System/Library/Frameworks/CoreServices.framework/Headers/CoreServices.h:21,
#                  from /System/Library/Frameworks/Carbon.framework/Headers/Carbon.h:20,
#                  from Include/pymactoolbox.h:10,
#                  from Python/mactoolboxglue.c:27:
# /System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/MachineExceptions.h:115: error: expected specifier-qualifier-list before 'vector'
# make: *** [Python/mactoolboxglue.o] Error 1
# if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
#     leopard.sh gcc-4.2
# fi
if ! test -e /opt/gcc-4.9.4 ; then
    tiger.sh gcc-libs-4.9.4
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
fi

# Tiger's /usr/bin/ld doesn't understand '-install_name'.
if ! test -e /opt/ld64-97.17 ; then
    tiger.sh ld64-97.17-tigerbrew
fi
export PATH="/opt/ld64-97.17/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Tiger's /usr/bin/ld doesn't understand '-install_name'.
# CC='gcc-4.2 -B/opt/ld64-97.17-tigerbrew/bin'
CC='gcc-4.9 -B/opt/ld64-97.17-tigerbrew/bin'

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# Don't include tk on ppc64.
if test -n "$ppc64" ; then
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

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
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

scripts_dir=/opt/$pkgspec/share/tiger.sh/$pkgspec
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

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
