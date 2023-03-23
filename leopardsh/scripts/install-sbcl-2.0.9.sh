#!/bin/bash
# based on templates/build-from-source.sh v6

# Install SBCL on OS X Leopard / PowerPC.

package=sbcl
version=2.0.9
upstream=https://downloads.sourceforge.net/$package/$package-$version-source.tar.bz2
description="Steel Bank Common Lisp"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

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

# An older version of SBCL is needed to perform the build.
if ! which -s sbcl ; then
    leopard.sh sbcl-1.0.47
fi

# We need gcc-4.9:
# gcc -g -mmacosx-version-min=10.4 -o sbcl alloc.o backtrace.o breakpoint.o coalesce.o coreparse.o dynbind.o funcall.o gc-common.o globals.o hopscotch.o interr.o interrupt.o largefile.o main.o monitor.o murmur_hash.o os-common.o parse.o print.o purify.o regnames.o runtime.o safepoint.o save.o sc-offset.o search.o thread.o time.o validate.o var-io.o vars.o wrap.o run-program.o ppc-arch.o bsd-os.o darwin-os.o ppc-darwin-os.o fullcgc.o gencgc.o traceroot.o ppc-assem.o -lSystem -lc -lm
# Undefined symbols:
#   "___sync_fetch_and_add", referenced from:
#       _gencgc_handle_wp_violation in gencgc.o
#   "___sync_fetch_and_and", referenced from:
#       _scan_weak_hashtable in gc-common.o
#   "___sync_fetch_and_or", referenced from:
#       _scan_weak_hashtable in gc-common.o
# ld: symbol(s) not found
# collect2: ld returned 1 exit status
# make: *** [sbcl] Error 1
if ! which -s gcc-4.9 ; then
    leopard.sh gcc-4.9.4
fi
CC=gcc-4.9

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

for f in src/runtime/Config.ppc-darwin ; do
    sed -i '' -e 's/ -g //' $f
    sed -i '' -e "s/ -O2 / $(leopard.sh -mcpu -O) /" $f
    sed -i '' -e 's/-mmacosx-version-min=10.4/-mmacosx-version-min=10.5/g' $f
    sed -i '' -e 's/OS_LIBS = -lSystem -lc/OS_LIBS = -lSystem -lc -lgcc/' $f
    sed -i '' -e 's/CPPFLAGS += -no-cpp-precomp/#CPPFLAGS += -no-cpp-precomp/' $f
    sed -i '' -e 's/CC = gcc/CC = gcc-4.9/' $f
done

/usr/bin/time ./make.sh --prefix=/opt/$pkgspec \
    --with-sb-core-compression

    # --with-sb-thread
# Threads are unavailable:
# ppc-darwin-os.c:28:2: error: #error "Define threading support functions"
#  #error "Define threading support functions"
#   ^
# gcc-4.9 -Wall -Os -fdollars-in-identifiers -mmacosx-version-min=10.5 -I.  -c -o alloc.o alloc.c
# In file included from target-os.h:88:0,
#                  from os.h:59,
#                  from globals.h:19,
#                  from thread.h:8,
#                  from gc-internal.h:28,
#                  from alloc.h:17,
#                  from alloc.c:17:
# darwin-os.h:41:31: fatal error: dispatch/dispatch.h: No such file or directory
#  #include <dispatch/dispatch.h>

# TODO: make a tex package and build the docs
# cd doc/manual
# make info html
# cd - >/dev/null

if test -n "$LEOPARDSH_RUN_LONG_TESTS" ; then
    cd tests
    sh run-tests.sh
    cd - >/dev/null
# Finished running tests.
# Status:
#  Expected failure:   array.pure.lisp / CHECK-BOUND-SIGNED-BOUND-NOTES
#  Expected failure:   compiler-2.pure.lisp / (MAP-ALLOCATED-OBJECTS NO-CONSING)
#  Failure:            compiler-2.pure.lisp / MODULAR-ARITH-TYPE-DERIVERS
#  Expected failure:   compiler-2.pure.lisp / DEDUPLICATED-FDEFNS
#  Failure:            compiler.pure.lisp / (ODDP BIGNUM NO-CONSING)
#  Failure:            compiler.pure.lisp / (LOGTEST BIGNUM NO-CONSING)
#  Failure:            compiler.pure.lisp / REDUCING-CONSTANTS
#  Failure:            compiler.pure.lisp / REDUCING-CONSTANTS.2
#  Failure:            defglobal.pure.lisp / DEFCONSTANT-EVALS
#  Failure:            defglobal.pure.lisp / DEFGLOBAL-REFERS-TO-DEFGLOBAL
#  Expected failure:   float.pure.lisp / (SCALE-FLOAT-OVERFLOW BUG-372)
#  Expected failure:   float.pure.lisp / (ADDITION-OVERFLOW BUG-372)
#  Expected failure:   float.pure.lisp / (ADDITION-OVERFLOW BUG-372 TAKE-2)
#  Expected failure:   hash.pure.lisp / SXHASH-ON-DISPLACED-STRING
#  Failure:            interface.pure.lisp / (SLEEP BUG-1194673)
#  Skipped (broken):   interface.pure.lisp / RESTART-BOGUS-ARG-TO-VALUES-LIST-ERROR
#  Failure:            octets.pure.lisp / COMPILE-FILE-POSITION-WITH-ENCODINGS
#  Failure:            compiler.impure.lisp / REGRESSION-1.0.29.54
#  Expected failure:   compiler.impure.lisp / BUG-308921
#  Expected failure:   compiler.impure.lisp / FTYPE-RETURN-TYPE-CONFLICT
#  Failure:            deadline.impure.lisp / (WITH-DEADLINE SLEEP NO-SLEEP)
#  Unexpected success: debug.impure.lisp / (TRACE ENCAPSULATE NIL)
#  Unexpected success: debug.impure.lisp / (TRACE ENCAPSULATE NIL RECURSIVE)
#  Expected failure:   debug.impure.lisp / PROPERLY-TAGGED-P-INTERNAL
#  Expected failure:   dynamic-extent.impure.lisp / DX-COMPILER-NOTES
#  Failure:            float.impure.lisp / (RANGE-REDUCTION PRECISE-PI)
#  Expected failure:   fopcompiler.impure.lisp / FOPCOMPILER-DEPRECATED-VAR-WARNING
#  Expected failure:   full-eval.impure.lisp / INLINE-FUN-CAPTURES-DECL
#  Failure:            gc.impure.lisp / (SEARCH-ROOTS SIMPLE-FUN)
#  Failure:            load.impure.lisp / LOAD-LISP-FILE-STREAM
#  Failure:            load.impure.lisp / LOAD-FASL-FILE-STREAM
#  Failure:            load.impure.lisp / LOAD-SOURCE-FILE-FULL-PATHNAME
#  Failure:            load.impure.lisp / LOAD-SOURCE-FILE-PARTIAL-PATHNAME
#  Failure:            load.impure.lisp / LOAD-SOURCE-FILE-DEFAULT-TYPE
#  Failure:            load.impure.lisp / LOAD-FASL-FILE
#  Failure:            load.impure.lisp / LOAD-FASL-FILE-PARTIAL-PATHNAME
#  Failure:            load.impure.lisp / LOAD-FASL-FILE-DEFAUT-TYPE
#  Failure:            load.impure.lisp / LOAD-FASL-FILE-STRANGE-TYPE
#  Failure:            load.impure.lisp / LOAD-DEFAULT-OBSOLETE-FASL-RESTART-SOURCE
#  Failure:            load.impure.lisp / LOAD-DEFAULTED-OBSOLETE-FASL-RESTART-OBJECT
#  Expected failure:   packages.impure.lisp / USE-PACKAGE-CONFLICT-SET
#  Expected failure:   packages.impure.lisp / IMPORT-SINGLE-CONFLICT
#  Failure:            timer.impure.lisp / (TIMER RELATIVE)
#  Failure:            timer.impure.lisp / (TIMER ABSOLUTE)
#  Failure:            timer.impure.lisp / (TIMER REPEAT-AND-UNSCHEDULE)
#  Failure:            timer.impure.lisp / (TIMER RESCHEDULE)
#  Failure:            timer.impure.lisp / (TIMER STRESS)
#  Failure:            timer.impure.lisp / (TIMER STRESS2)
#  Failure:            timer.impure.lisp / (WITH-TIMEOUT TIMEOUT)
#  Failure:            timer.impure.lisp / (WITH-TIMEOUT NESTED-TIMEOUT-SMALLER)
#  Failure:            timer.impure.lisp / (WITH-TIMEOUT NESTED-TIMEOUT-BIGGER)
#  Skipped (broken):   timer.impure.lisp / (TIMER PARALLEL-UNSCHEDULE)
#  Failure:            /tmp/sbcl444wozmfbldfe.fasl / GC-ANONYMOUS-LAYOUT
#  (105 tests skipped for this combination of platform and features)
# test failed, expected 104 return code, got 1
fi

INSTALL_ROOT=/opt/$pkgspec ./install.sh

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
