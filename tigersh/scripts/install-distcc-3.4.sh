#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install distcc on OS X Tiger / PowerPC.

package=distcc
version=3.4
upstream=https://github.com/$package/$package/releases/download/v$version/$package-$version.tar.gz
description="Distributed C/C++/ObjC compiler with distcc-pump extensions"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    gcc-libs-4.9.4 \
    python-3.11.2$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

# distcc needs to compile a python extension, and python-3.11.2 will expect gcc-4.9.4.
if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# distccd seems to choke on the default ipv6 addresses when using --allow-private:
#   distccd[21339] (dcc_parse_mask) ERROR: can't parse internet address "fe80::"
# We don't care about ipv6 on a local network anyway, so just nix them.
patch -p1 << 'EOF'
diff -urN distcc-3.4/src/dopt.c distcc-3.4.patched/src/dopt.c
--- distcc-3.4/src/dopt.c	2021-05-11 12:29:22.000000000 -0500
+++ distcc-3.4.patched/src/dopt.c	2023-02-21 09:52:40.000000000 -0600
@@ -129,9 +129,9 @@
                                              "172.16.0.0/12",
                                              "127.0.0.0/8",
 
-                                             "fe80::/10",
-                                              "fc00::/7",
-                                              "::1/128"};
+                                             "127.0.0.0/8",
+                                              "127.0.0.0/8",
+                                              "127.0.0.0/8"};
 
 const struct poptOption options[] = {
     { "allow", 'a',      POPT_ARG_STRING, 0, 'a', 0, 0 },
EOF

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --without-libiberty \
    --without-avahi \
    PYTHON=/opt/python-3.11.2/bin/python3

sed -i '' -e "s/CFLAGS = -g -O2 /CFLAGS = $CFLAGS /" Makefile

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
