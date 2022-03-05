#!/bin/bash
# based on templates/install-foo-1.0.sh v3

# Install gettext on OS X Tiger / PowerPC.

# Note: gettext provides libintl.

package=gettext
version=0.21

set -e -x
PATH="/opt/portable-curl/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# Note: there is a dependency cycle between gettext and libiconv.
# See the note in install-libiconv-bootstrap-1.16.sh.
if ! test -e /opt/libiconv-bootstrap-1.16$ppc64 ; then
    tiger.sh libiconv-bootstrap-1.16$ppc64
fi

if ! test -e /opt/libunistring-1.0$ppc64 ; then
    tiger.sh libunistring-1.0$ppc64
fi

if ! test -e /opt/xz-5.2.5$ppc64 ; then
    tiger.sh xz-5.2.5$ppc64
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(hostname -s))\007"

binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz
if curl -sSfI $TIGERSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$TIGERSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $TIGERSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://ftp.gnu.org/gnu/$package
    tarball=$package-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version

    tar xzf ~/Downloads/$tarball

    cd $package-$version

    cp ~/tmp/gettext/get_ppid_of.h libtextstyle/lib/
    cp ~/tmp/gettext/fix2/get_ppid_of.c libtextstyle/lib/

    cp ~/tmp/gettext/get_progname_of.h libtextstyle/lib/
    cp ~/tmp/gettext/fix2/get_progname_of.c libtextstyle/lib/

    cat /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache > config.cache

    if test -n "$ppc64" ; then
        CFLAGS="-m64 $(tiger.sh -mcpu -O)"
        CXXFLAGS="-m64 $(tiger.sh -mcpu -O)"
        export LDFLAGS=-m64
    else
        CFLAGS=$(tiger.sh -m32 -mcpu -O)
        CXXFLAGS=$(tiger.sh -m32 -mcpu -O)
    fi
    export CFLAGS CXXFLAGS

    ./configure -C --prefix=/opt/$pkgspec \
        --with-libiconv-prefix=/opt/libiconv-bootstrap-1.16$ppc64 \
        --with-libcurses-prefix=/opt/ncurses-6.3$ppc64 \
        --with-libunistring-prefix=/opt/libunistring-1.0$ppc64
        # LIBS=-lproc

    make $(tiger.sh -j) V=1

    if test -n "$TIGERSH_RUN_TESTS" ; then
        make check
    fi

    make install

    if test -e config.cache ; then
        mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
        gzip config.cache
        mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
    fi
fi

if test -e /opt/$pkgspec/bin ; then
    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/
fi

if test -e /opt/$pkgspec/sbin ; then
    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/
fi

# tiger ppc failing:
# gcc -std=gnu99 -DHAVE_CONFIG_H -I. -I..  -I. -I. -I.. -I.. -Iglib -DIN_LIBTEXTSTYLE -DLIBXML_STATIC    -I./libcroco  -DDEPENDS_ON_LIBICONV=1   -mcpu=7450 -O2 -c get_ppid_of.c
# get_ppid_of.c:36:22: error: libproc.h: No such file or directory
# get_ppid_of.c: In function 'get_ppid_of':
# get_ppid_of.c:241: error: storage size of 'info' isn't known
# get_ppid_of.c:243: warning: implicit declaration of function 'proc_pidinfo'
# get_ppid_of.c:243: error: 'PROC_PIDTBSDINFO' undeclared (first use in this function)
# get_ppid_of.c:243: error: (Each undeclared identifier is reported only once
# get_ppid_of.c:243: error: for each function it appears in.)
# make[4]: *** [config.h] Error 1
# make[3]: *** [all-recursive] Error 1
# make[2]: *** [all] Error 2
# make[1]: *** [all-recursive] Error 1
# make: *** [all] Error 2
#       362.49 real       137.15 user       177.23 sys

# see related tigerbrew issue: https://github.com/mistydemeo/tigerbrew/issues/426
# I don't have /usr/lib/libproc.dylib, and ppc tiger doesn't ship a libproc.h

# see https://opensource.apple.com/releases/
# libproc.h and libproc.c are part of Apple's "Libc" open source release.
# according to the above, 10.4.11 shipped with Libc-391.5.22
# see https://github.com/apple-oss-distributions/Libc/archive/Libc-391.5.22.tar.gz
# it looks like libproc.h and libproc.c weren't available until Libc-498 (which was 10.5.0):
# see https://opensource.apple.com/source/Libc/Libc-498/darwin/libproc.h
# see https://opensource.apple.com/source/Libc/Libc-498/darwin/libproc.c

# ok, after building a libproc.dylib, linking gettext still fails:

# libtool: link: gcc -std=gnu99 -dynamiclib  -o .libs/libtextstyle.0.dylib  .libs/gl_array_list.o .libs/basename-lgpl.o .libs/binary-io.o .libs/c-ctype.o .libs/c-strcasecmp.o .libs/c-strncasecmp.o .libs/cloexec.o .libs/concat-filename.o .libs/exitfail.o .libs/fatal-signal.o .libs/fd-hook.o .libs/fd-ostream.o .libs/file-ostream.o .libs/full-write.o .libs/get_ppid_of.o .libs/get_progname_of.o .libs/getprogname.o .libs/html-ostream.o .libs/html-styled-ostream.o .libs/iconv-ostream.o .libs/gl_list.o glthread/.libs/lock.o .libs/malloca.o .libs/math.o .libs/mem-hash-map.o .libs/memory-ostream.o .libs/noop-styled-ostream.o .libs/ostream.o .libs/printf-frexp.o .libs/printf-frexpl.o .libs/safe-read.o .libs/safe-write.o .libs/sig-handler.o .libs/sockets.o .libs/stat-time.o .libs/styled-ostream.o .libs/sys_socket.o .libs/term-ostream.o .libs/term-style-control.o .libs/term-styled-ostream.o glthread/.libs/threadlib.o .libs/unistd.o unistr/.libs/u8-mbtouc.o unistr/.libs/u8-mbtouc-aux.o .libs/xmalloc.o .libs/xstrdup.o .libs/xconcat-filename.o .libs/xgethostname.o .libs/gl_xlist.o .libs/xsize.o .libs/xvasprintf.o .libs/xasprintf.o .libs/color.o .libs/misc.o .libs/version.o .libs/asnprintf.o .libs/asprintf.o .libs/error.o .libs/fcntl.o .libs/frexpl.o .libs/obstack.o .libs/open.o .libs/printf-args.o .libs/printf-parse.o .libs/snprintf.o .libs/stat.o .libs/strerror.o .libs/strerror-override.o .libs/vasnprintf.o .libs/vasprintf.o   .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-additional-sel.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-attr-sel.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-cascade.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-declaration.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-doc-handler.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-enc-handler.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-fonts.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-input.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-num.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-om-parser.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-parser.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-parsing-location.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-prop-list.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-pseudo.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-rgb.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-sel-eng.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-selector.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-simple-sel.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-statement.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-string.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-style.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-stylesheet.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-term.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-tknzr.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-token.o .libs/libtextstyle.lax/libcroco_rpl.a/rpl_la-cr-utils.o  .libs/libtextstyle.lax/libglib_rpl.a/libglib_rpl_la-ghash.o .libs/libtextstyle.lax/libglib_rpl.a/libglib_rpl_la-glist.o .libs/libtextstyle.lax/libglib_rpl.a/libglib_rpl_la-gmessages.o .libs/libtextstyle.lax/libglib_rpl.a/libglib_rpl_la-gprimes.o .libs/libtextstyle.lax/libglib_rpl.a/libglib_rpl_la-gstrfuncs.o .libs/libtextstyle.lax/libglib_rpl.a/libglib_rpl_la-gstring.o  .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-DOCBparser.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-HTMLparser.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-HTMLtree.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-SAX.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-SAX2.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-buf.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-c14n.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-catalog.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-chvalid.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-debugXML.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-dict.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-encoding.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-entities.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-error.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-globals.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-hash.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-legacy.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-list.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-nanoftp.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-nanohttp.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-parser.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-parserInternals.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-pattern.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-relaxng.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-schematron.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-threads.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-tree.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-trionan.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-uri.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-valid.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xinclude.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xlink.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xmlIO.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xmlmemory.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xmlmodule.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xmlreader.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xmlregexp.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xmlsave.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xmlschemas.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xmlschemastypes.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xmlstring.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xmlunicode.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xmlwriter.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xpath.o .libs/libtextstyle.lax/libxml_rpl.a/rpl_la-xpointer.o   /usr/lib/libiconv.dylib -lncurses  -mcpu=7450 -O2   -install_name  /opt/gettext-0.21/lib/libtextstyle.0.dylib -compatibility_version 2 -current_version 2.1 -Wl,-single_module -Wl,-exported_symbols_list,.libs/libtextstyle-symbols.expsym
# ld: Undefined symbols:
# _proc_pidinfo
# /usr/libexec/gcc/powerpc-apple-darwin8/4.0.1/libtool: internal link edit command failed
# make[5]: *** [libtextstyle.la] Error 1
# make[4]: *** [all] Error 2
# make[3]: *** [all-recursive] Error 1
# make[2]: *** [all] Error 2
# make[1]: *** [all-recursive] Error 1
# make: *** [all] Error 2

# see also https://github.com/macports/macports-ports/pull/13226

# see also https://lists.gnu.org/archive/html/bug-gnulib/2021-12/msg00011.html
# see also https://lists.gnu.org/archive/html/bug-gnulib/2021-12/msg00049.html

# see patch at https://lists.gnu.org/archive/html/bug-gnulib/2021-12/msg00071.html

# here are the two attempted fixes:
# https://git.savannah.gnu.org/cgit/gnulib.git/commit/lib/get_ppid_of.c?id=8e3d5944a4c6fca1ecf1d76f669da83861eb0ca0
# https://git.savannah.gnu.org/cgit/gnulib.git/commit/lib/get_ppid_of.c?id=119622a83d47b01b5a9fb2af4542cdb45f4eb83b

# as files:
# https://git.savannah.gnu.org/cgit/gnulib.git/plain/lib/get_ppid_of.c?id=8e3d5944a4c6fca1ecf1d76f669da83861eb0ca0
# https://git.savannah.gnu.org/cgit/gnulib.git/plain/lib/get_ppid_of.c?id=119622a83d47b01b5a9fb2af4542cdb45f4eb83b

# the header file is the same for both:
# https://git.savannah.gnu.org/cgit/gnulib.git/plain/lib/get_ppid_of.h?id=8e3d5944a4c6fca1ecf1d76f669da83861eb0ca0

# you also need get_progname_of.c, here are the two fixes:
# https://git.savannah.gnu.org/cgit/gnulib.git/plain/lib/get_progname_of.c?id=8e3d5944a4c6fca1ecf1d76f669da83861eb0ca0
# https://git.savannah.gnu.org/cgit/gnulib.git/plain/lib/get_progname_of.c?id=119622a83d47b01b5a9fb2af4542cdb45f4eb83b

# and header:
# https://git.savannah.gnu.org/cgit/gnulib.git/plain/lib/get_progname_of.h?id=119622a83d47b01b5a9fb2af4542cdb45f4eb83b

# "fix1" now fails to compile on tiger:
# gcc -std=gnu99 -DHAVE_CONFIG_H -I. -I..  -I. -I. -I.. -I.. -Iglib -DIN_LIBTEXTSTYLE -DLIBXML_STATIC    -I./libcroco  -DDEPENDS_ON_LIBICONV=1   -m32 -mcpu=970 -O2 -c get_progname_of.c
# In file included from get_progname_of.c:21:
# get_progname_of.h:32: error: parse error before '_GL_ATTRIBUTE_DEALLOC_FREE'
# make[4]: *** [config.h] Error 1
# make[3]: *** [all-recursive] Error 1
# make[2]: *** [all] Error 2
# make[1]: *** [all-recursive] Error 1
# make: *** [all] Error 2

# same failure on leopard

# line 32 is:
# 31: extern char *get_progname_of (pid_t pid)
# 32:  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC_FREE;
