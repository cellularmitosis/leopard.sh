#!/bin/bash

# build the dependencies needed for tiger.sh.

set -e -x

# ensure we are running on a g3 running tiger.
test "$( tiger.sh --os.cpu )" = "tiger.g3"

tiger.sh --setup

opt=/opt/tigersh-deps-0.1

rm -rf $opt

# grab a copy of cacert.pem
echo -n -e "\033]0;fetch cacert.pem\007"
if ! test -e ~/Downloads/cacert.pem ; then
    cd ~/Downloads
    /opt/portable-curl/bin/curl -#fLO https://curl.se/ca/cacert.pem
    cd - >/dev/null
fi
mkdir -p $opt/share
cd $opt/share
cp ~/Downloads/cacert.pem .

# build pv
echo -n -e "\033]0;building pv\007"
package=pv
version=1.6.20
srcmirror=https://distfiles.gentoo.org/distfiles
tarball=$package-$version.tar.bz2
if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    /opt/portable-curl/bin/curl -#fLO $srcmirror/$tarball
    cd - >/dev/null
fi
test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 85b25c827add82ebdd5a58a5ffde1d7d
cd /tmp
rm -rf $package-$version
tar xjf ~/Downloads/$tarball
cd $package-$version
cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache
./configure -C --prefix=$opt CFLAGS="-mcpu=750 -Os"
make V=1
make install

# build libressl
echo -n -e "\033]0;building libressl\007"
package=libressl
version=3.4.2
srcmirror=https://ftp.openbsd.org/pub/OpenBSD/LibreSSL
tarball=$package-$version.tar.gz
if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
    /opt/portable-curl/bin/curl -#fLO $srcmirror/$tarball
    cd - >/dev/null
fi
test "$(md5 ~/Downloads/$tarball | awk '{print $NF}')" = 18aa728e7947a30af3bb04243e4482aa
cd /tmp
rm -rf $package-$version
tar xzf ~/Downloads/$tarball
cd $package-$version
cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache
./configure -C --prefix=$opt CFLAGS="-mcpu=750 -Os"
make V=1
make install

# build curl
echo -n -e "\033]0;building curl\007"
package=curl
version=7.81.0
srcmirror=https://curl.se/download
tarball=$package-$version.tar.gz
if ! test -e ~/Downloads/$tarball ; then
    cd ~/Downloads
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
./configure -C --prefix=$opt \
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
make V=1
make install

# create a staging area in /tmp/tigersh-deps-0.1
echo -n -e "\033]0;packaging\007"
rm -rf /tmp/tigersh-deps-0.1
mkdir /tmp/tigersh-deps-0.1
cd /tmp/tigersh-deps-0.1
mkdir bin lib share
cp $opt/bin/pv bin/
cp $opt/bin/curl bin/
cp $opt/lib/libssl.50.dylib lib/
cp $opt/lib/libcrypto.47.dylib lib/
cp $opt/share/cacert.pem share/

cd /tmp
tar c tigersh-deps-0.1 | gzip > tigersh-deps-0.1.tiger.g3.tar.gz

rm -rf $opt
mv /tmp/tigersh-deps-0.1 /opt
