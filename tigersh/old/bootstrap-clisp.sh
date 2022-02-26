#!/bin/bash

# note: this took 86 minutes on emac3 (1.25GHz G4).

set -e -x

if ! test -e /opt/libsigsegv-2.5 ; then
    tiger.sh libsigsegv-2.5
fi

cd /tmp
rm -rf clisp-2.39
cat ~/Downloads/clisp-2.39.tar.gz | gunzip | tar x
cd /tmp/clisp-2.39

#CPPFLAGS=-I/opt/libsigsegv-2.14/include \
#LDFLAGS=-L/opt/libsigsegv-2.14/lib \
./configure --prefix=/tmp/opt/clisp-2.39 \
    --with-libsigsegv-prefix=/opt/libsigsegv-2.5
#    --with-libiconv-prefix=/opt/libiconv-x.y.z \
#    --with-libreadline-prefix=/opt/libreadline-x.y.z \

cd src
./makemake \
    --with-dynamic-ffi \
    --prefix=/tmp/opt/clisp-2.39 \
    > Makefile

# from makemake --help:
#       --with-noreadline       do not use readline library (even when present)
#       --with-gettext          internationalization, needs GNU gettext
#       --with-nogettext        static internationalization (en only)
#       --without-unicode       no Unicode character set, only 8-bit characters
#       --with-dynamic-ffi      a foreign language interface
#       --with-dynamic-modules  dynamic loading of foreign language modules
#       --with-threads=FLAVOR   MT [_experimental_!]
#                               FLAVOR: POSIX_THREADS POSIXOLD_THREADS
#                                       SOLARIS_THREADS C_THREADS WIN32_THREADS
#       --with-gmalloc          use the GNU malloc instead of of the libc one
#                               (needed on HP-UX and OpenBSD)
#    See modules/ directory for available modules and add them to the full
#    linking set using --with-module option, e.g.,
#       --with-module=bindings/glibc
#       --with-module=pari

make config.lisp
# vim config.lisp
make
make check
make install
