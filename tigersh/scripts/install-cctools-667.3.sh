#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install cctools on OS X Tiger / PowerPC.

package=cctools
# Note: 667.3 is the version which shipped with Leopard.
version=667.3
upstream=https://ftp.gnu.org/gnu/$package/$package-$version.tar.gz
description="Apple's ar, as, nm, otool, libtool, lipo, etc. (Leopard version)"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Apple ships this tarball with all files read-only.
chmod -R u+w .

# For whatever reason, '#include <ar.h>' is not seeing /usr/include/ar.h.
ln -s /usr/include/ar.h include/

# Fails due to missing streams/streams.h
#   cc -g -I.. -I../../include -I. -Wall -Wno-long-double -no-cpp-precomp -fno-builtin-round -fno-builtin-trunc -DRLD -DKLD -O  -c -MD \
#   	-dependency-file ./layout.d -o ./layout.o ../layout.c
#   In file included from ../layout.c:72:
#   ../../include/mach-o/rld.h:30:29: error: streams/streams.h: No such file or directory
# This is a private header, which I can't seem to locate.
# Whatever, just grab a temporary copy to make the compiler happy.
curl --fail $TIGERSH_MIRROR/dist/Libstreams-22.tar.gz \
    | gunzip \
    | tar x Libstreams-Libstreams-22/streams.h
mkdir -p include/streams
mv Libstreams-Libstreams-22/streams.h include/streams
rmdir Libstreams-Libstreams-22

for f in */Makefile ; do
    # Tiger's libtool doesn't understand '-static'.  Just use 'ar' instead.
    sed -i '' -e 's/libtool -static -o/ar -crs/' $f
    # Drop the -g flag.
    sed -i '' -e 's/ -g / /' $f
    sed -i '' -e 's/"-g /" /' $f
    # Quote the OFLAG option to allow spaces.
    sed -i '' -e 's/OFLAG=$(OFLAG)/OFLAG="$(OFLAG)"/' $f
done

# Fails due to missing seg_hack:
#   seg_hack __KLD ./prehack_libkld.a -o ./static_libkld.o
#   make[2]: seg_hack: Command not found
#   make[2]: *** [libkld.a] Error 127
# However, this binary was just built, as misc/seg_hack.NEW.
sed -i '' -e 's|seg_hack|../../misc/seg_hack.NEW|' ld/Makefile

CFLAGS=$(tiger.sh -mcpu -O)

/usr/bin/time make $(tiger.sh -j) DSTROOT=/opt/$pkgspec OFLAG="$CFLAGS"

# Note: no 'make check' available.

make DSTROOT=/opt/$pkgspec install
# The cctools Makefile was not designed for /opt installation.
cd /opt/$pkgspec
mv usr/* .
rmdir usr
rm local/bin/nmedit
mv local/bin/* bin/
mv local/lib .
rsync -a local/include/ include/
rsync -a local/libexec/ libexec/
rsync -a local/man/ share/man/
rm -rf local/include local/libexec local/man
cd -

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
