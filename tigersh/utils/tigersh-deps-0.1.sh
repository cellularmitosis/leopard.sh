#!/bin/bash

# bootstrap the dependencies needed by tiger.sh.

set -e -x

osversion=$(sw_vers -productVersion | awk '{print $NF}')
if ! test "${osversion:0:4}" = "10.4" ; then
    echo "Sorry, this script needs to be run on OS X Tiger :(" >&2
    exit 1
fi

cpu_id=$(sysctl hw.cpusubtype | awk '{print $NF}')
if ! test "$cpu_id" = "9" ; then
    echo "Sorry, this script needs to be run on a G3 CPU :(" >&2
    exit 1
fi

# FIXME get rid of this circular bootstrap dependency situation.
# Tell the user to download the dist files on another PC if needed.
tiger.sh --setup

opt=/opt/tigersh-deps-0.1

rm -rf $opt

# build pv
echo -n -e "\033]0;building pv\007"
package=pv
version=1.6.20
srcmirror=https://distfiles.gentoo.org/distfiles
tarball=$package-$version.tar.bz2
if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    # FIXME get rid of this circular bootstrap dependency situation.
    # Tell the user to download the dist files on another PC if needed.
    /opt/portable-curl/bin/curl -#fLO $srcmirror/$tarball
    cd - >/dev/null
fi
test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 85b25c827add82ebdd5a58a5ffde1d7d
cd /tmp
rm -rf $package-$version
tar xjf ~/Downloads/$tarball
cd $package-$version
cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache
nice ./configure -C --prefix=$opt CFLAGS="-mcpu=750 -Os"
nice make V=1
make install

# build otool which understand ppc64
echo -n -e "\033]0;building otool\007"
package=otool
version=667.3
srcmirror=https://github.com/apple-oss-distributions/cctools/archive
tarball=cctools-$version.tar.gz
if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    # FIXME get rid of this circular bootstrap dependency situation.
    # Tell the user to download the dist files on another PC if needed.
    /opt/portable-curl/bin/curl -#fLO $srcmirror/$tarball
    cd - >/dev/null
fi
test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = e90e5b27f96eddacd966a3f983a80cbf
cd /tmp
rm -rf cctools-cctools-$version
tar xzf ~/Downloads/$tarball
cd cctools-cctools-$version
# For whatever reason, '#include <ar.h>' is not seeing /usr/include/ar.h.
ln -s /usr/include/ar.h include/
cd libstuff
nice make OFLAG="-mcpu=750 -Os"
cd ..
cd otool
nice make OFLAG="-mcpu=750 -Os"
cd ..
cp otool/otool.NEW $opt/bin/otool

# build libressl
echo -n -e "\033]0;building libressl\007"
package=libressl
version=3.4.2
srcmirror=https://ftp.openbsd.org/pub/OpenBSD/LibreSSL
tarball=$package-$version.tar.gz
if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    # FIXME get rid of this circular bootstrap dependency situation.
    # Tell the user to download the dist files on another PC if needed.
    /opt/portable-curl/bin/curl -#fLO $srcmirror/$tarball
    cd - >/dev/null
fi
test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 18aa728e7947a30af3bb04243e4482aa
cd /tmp
rm -rf $package-$version
tar xzf ~/Downloads/$tarball
cd $package-$version
cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache
nice ./configure -C --prefix=$opt CFLAGS="-mcpu=750 -Os"
nice make V=1
make install

# grab a copy of cacert.pem
echo -n -e "\033]0;fetch cacert.pem\007"
if ! test -e ~/Downloads/cacert.pem ; then
    cd ~/Downloads
    # FIXME get rid of this circular bootstrap dependency situation.
    # Tell the user to download the dist files on another PC if needed.
    /opt/portable-curl/bin/curl -#fLO https://curl.se/ca/cacert.pem
    cd - >/dev/null
fi
mkdir -p $opt/share
cd $opt/share
cp ~/Downloads/cacert.pem .

# build curl with modern SSL support
echo -n -e "\033]0;building curl\007"
package=curl
version=7.81.0
srcmirror=https://curl.se/download
tarball=$package-$version.tar.gz
if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    # FIXME get rid of this circular bootstrap dependency situation.
    # Tell the user to download the dist files on another PC if needed.
    /opt/portable-curl/bin/curl -#fLO $srcmirror/$tarball
    cd - >/dev/null
fi
test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 9e5e81fc7657eea8dc66672768082c46
cd /tmp
rm -rf $package-$version
tar xzf ~/Downloads/$tarball
cd $package-$version
cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache
# all we need are http://, https://, ftp:// and file://
nice ./configure -C --prefix=$opt \
    --disable-debug --disable-curldebug \
    --disable-dependency-tracking \
    --enable-static --disable-shared \
    --enable-ipv6 --enable-http --enable-ftp --enable-file \
    --disable-ldap --disable-rtsp --disable-proxy --disable-dict \
    --disable-telnet --disable-tftp --disable-pop3 --disable-imap \
    --disable-smb --disable-smtp --disable-gopher --disable-mqtt \
    --disable-manual --disable-libcurl-option \
    --with-openssl=$opt \
    --with-ca-bundle=$opt/share/cacert.pem \
    CFLAGS="-mcpu=750 -Os"
nice make V=1
make install

# create a staging area in /tmp/tigersh-deps-0.1
echo -n -e "\033]0;packaging\007"
rm -rf /tmp/tigersh-deps-0.1
mkdir /tmp/tigersh-deps-0.1
cd /tmp/tigersh-deps-0.1
mkdir bin lib share
cp $opt/bin/pv bin/
cp $opt/bin/otool bin/
cp $opt/bin/curl bin/
cp $opt/lib/libssl.50.dylib lib/
cp $opt/lib/libcrypto.47.dylib lib/
cp $opt/share/cacert.pem share/

cd /tmp
tar c tigersh-deps-0.1 | nice gzip -9 > tigersh-deps-0.1.tiger.g3.tar.gz

rm -rf $opt
mv /tmp/tigersh-deps-0.1 /opt
