#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install zstd on OS X Tiger / PowerPC.

package=zstd
version=1.5.1
upstream=https://github.com/facebook/$package/releases/download/v$version/$package-$version.tar.gz

# fails to build using stock tiger gcc:
# cc -DXXH_NAMESPACE=ZSTD_ -DDEBUGLEVEL=0 -DZSTD_LEGACY_SUPPORT=5 -DZSTD_MULTITHREAD  -mcpu=7450 -O2   -fPIC -fvisibility=hidden -shared -pthread obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/debug.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/entropy_common.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/error_private.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/fse_decompress.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/pool.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/threading.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/xxhash.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_common.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_v05.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_v06.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_v07.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/fse_compress.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/hist.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/huf_compress.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_compress.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_compress_literals.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_compress_sequences.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_compress_superblock.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_double_fast.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_fast.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_lazy.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_ldm.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_opt.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstdmt_compress.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/huf_decompress.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_ddict.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_decompress.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zstd_decompress_block.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/huf_decompress_amd64.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/cover.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/divsufsort.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/fastcover.o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/zdict.o -shared -pthread -install_name /opt/zstd-1.5.1/lib/libzstd.1.dylib -dynamiclib -compatibility_version 1 -current_version 1.5.1 -o obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/libzstd.1.5.1.dylib
# powerpc-apple-darwin8-gcc-4.0.1: unrecognized option '-shared'
# powerpc-apple-darwin8-gcc-4.0.1: unrecognized option '-pthread'
# powerpc-apple-darwin8-gcc-4.0.1: unrecognized option '-shared'
# powerpc-apple-darwin8-gcc-4.0.1: unrecognized option '-pthread'
# ld: common symbols not allowed with MH_DYLIB output format with the -multi_module option
# obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/threading.o private external definition of common _g_ZSTD_threading_useless_symbol (size 4)
# /usr/libexec/gcc/powerpc-apple-darwin8/4.0.1/libtool: internal link edit command failed
# make[2]: *** [Makefile:161: obj/conf_be95a23b7339dcc3f1bcce2052683006/dynamic/libzstd.1.5.1.dylib] Error 1
# make[1]: *** [Makefile:148: libzstd.1.5.1.dylib] Error 2
# make[1]: Leaving directory '/private/tmp/zstd-1.5.1/lib'
# make: *** [Makefile:63: lib-release] Error 2

# fails to build with gcc-4.2:
# compiling multi-threaded dynamic library 1.5.1
# gcc-4.2 -DXXH_NAMESPACE=ZSTD_ -DDEBUGLEVEL=0 -DZSTD_LEGACY_SUPPORT=5 -DZSTD_MULTITHREAD  -mcpu=7450 -O2   -fPIC -fvisibility=hidden -shared -pthread obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/debug.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/entropy_common.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/error_private.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/fse_decompress.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/pool.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/threading.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/xxhash.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_common.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_v05.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_v06.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_v07.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/fse_compress.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/hist.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/huf_compress.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_compress.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_compress_literals.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_compress_sequences.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_compress_superblock.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_double_fast.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_fast.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_lazy.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_ldm.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_opt.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstdmt_compress.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/huf_decompress.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_ddict.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_decompress.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zstd_decompress_block.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/huf_decompress_amd64.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/cover.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/divsufsort.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/fastcover.o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/zdict.o -shared -pthread -install_name /opt/zstd-1.5.1/lib/libzstd.1.dylib -dynamiclib -compatibility_version 1 -current_version 1.5.1 -o obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/libzstd.1.5.1.dylib
# /usr/libexec/gcc/powerpc-apple-darwin8/4.2.1/ld: common symbols not allowed with MH_DYLIB output format with the -multi_module option
# obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/threading.o private external definition of common _g_ZSTD_threading_useless_symbol (size 4)
# collect2: ld returned 1 exit status
# make[2]: *** [Makefile:161: obj/conf_8789700234b01ebcb28420d6f0a612c3/dynamic/libzstd.1.5.1.dylib] Error 1
# make[1]: *** [Makefile:148: libzstd.1.5.1.dylib] Error 2
# make[1]: Leaving directory '/private/tmp/zstd-1.5.1/lib'
# make: *** [Makefile:63: lib-release] Error 2

# see https://wiki.tcl-lang.org/page/MacTcl

# see https://trac.macports.org/ticket/63744

# this also takes a lot longer to build than on leopard.  perhaps tiger is trying
# to build additional components?

# fails to build with gcc-4.9.4
# /usr/bin/ld: common symbols not allowed with MH_DYLIB output format with the -multi_module option
# obj/conf_d46559ffe0929c277f402b06f3b1bee8/dynamic/threading.o private external definition of common _g_ZSTD_threading_useless_symbol (size 4)
# collect2: error: ld returned 1 exit status
# make[2]: *** [Makefile:161: obj/conf_d46559ffe0929c277f402b06f3b1bee8/dynamic/libzstd.1.5.1.dylib] Error 1
# make[1]: *** [Makefile:148: libzstd.1.5.1.dylib] Error 2
# make[1]: Leaving directory '/private/tmp/zstd-1.5.1/lib'
# make: *** [Makefile:63: lib-release] Error 2

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

# Note: fails to build on tiger using gcc and gcc-4.2, so we use gcc-4.9.
# Note: ppc64 gcc-4.9.4 unavailable.
if ! test -e /opt/gcc-4.9.4 ; then
    tiger.sh gcc-4.9.4
fi

# Note: the stock 'make' on tiger is 3.80, which causes a failure:
# make -C lib lib-release
# libzstd.mk:166: Extraneous text after `else' directive
# libzstd.mk:168: Extraneous text after `else' directive
# libzstd.mk:168: *** only one `else' per conditional.  Stop.
# make: *** [lib-release] Error 2
#
# (Surprisingly, leopard's make 3.81 doesn't have this problem.)
if ! test -e /opt/make-4.3$ppc64 ; then
    tiger.sh make-4.3$ppc64
    PATH="/opt/make-4.3$ppc64/bin:$PATH"
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Fix for '-compatibility_version only allowed with -dynamiclib' error:
perl -pi -e "s/-compatibility_version/-dynamiclib -compatibility_version/" lib/Makefile

for f in Makefile */Makefile */*/Makefile */*.mk ; do
    if test -n "$ppc64" ; then
        perl -pi -e "s/-O3/-m64 $(tiger.sh -mcpu -O)/g" $f
    else
        perl -pi -e "s/-O3/$(tiger.sh -mcpu -O)/g" $f
    fi
done

/usr/bin/time make $(tiger.sh -j) V=1 prefix=/opt/$pkgspec CC=gcc-4.9

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

make prefix=/opt/$pkgspec install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64
