#!/bin/bash
# based on templates/template.sh v1

if test "$(tiger.sh --cpu)" = "g5"; then
    echo "ERROR: this version of mpfr doesn't work on G5 with -m32." >&2
    echo "See the bug number 1 description on the following page:" >&2
    echo "https://mpfr.org/mpfr-3.1.0" >&2
    exit 1
fi

# Install mpfr on OS X Tiger / PowerPC.

package=mpfr
version=2.4.2

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if ! test -e /opt/gmp-4.3.2; then
    tiger.sh gmp-4.3.2
fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$package-$version.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD"; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd $package-$version

    # Note: disabling thread-safe because thread-local storage isn't supported until gcc 4.9.
    ./configure -C --prefix=/opt/$package-$version \
        --disable-thread-safe \
        --with-gmp=/opt/gmp-4.3.2 \
        CFLAGS="-Wall -Wmissing-prototypes -Wpointer-arith $(tiger.sh -m64 -mcpu -O)"

    make $(tiger.sh -j)

    if test -n "$TIGERSH_MAKE_CHECK"; then
        make check
    fi

    make install

    if test "$(tiger.sh --cpu)" = "g5"; then
        # On G5, build universal libs which contain both ppc and ppc64.
        cd /tmp/$package-$version
        make clean

        ./configure --prefix=/opt/$package-$version \
            --disable-thread-safe \
            --with-gmp=/opt/gmp-4.3.2 \
            CFLAGS="-Wall -Wmissing-prototypes -Wpointer-arith -m32 $(tiger.sh -mcpu -O)"

        make $(tiger.sh -j) V=1

        if test -n "$TIGERSH_MAKE_CHECK"; then
            make check
        fi

        for f in libmpfr.1.dylib ; do
            mv /opt/$package-$version/lib/$f /opt/$package-$version/lib/$f.orig
            lipo -create \
                -arch ppc64 /opt/$package-$version/lib/$f.orig \
                -arch ppc /tmp/$package-$version/.libs/$f \
                -output /opt/$package-$version/lib/$f
            rm /opt/$package-$version/lib/$f.orig
        done
    fi
fi
