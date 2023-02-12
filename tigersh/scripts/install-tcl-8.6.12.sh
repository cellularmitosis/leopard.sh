#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install tcl on OS X Tiger / PowerPC.

package=tcl
version=8.6.12
upstream=https://prdownloads.sourceforge.net/tcl/tcl$version-src.tar.gz
description="Tool Command Language"

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

if test -n "$ppc64" ; then
    # Note: the 64-bit build (when using -O2) will fail when using stock gcc:
    #   gcc -dynamiclib -Os -m64 -mcpu=970 -O2 -pipe  -arch ppc64 -mpowerpc64 -mcpu=G5     -headerpad_max_install_names -Wl,-search_paths_first  -Wl,-single_module -o libtcl8.6.dylib regcomp.o regexec.o regfree.o regerror.o tclAlloc.o tclAssembly.o tclAsync.o tclBasic.o tclBinary.o tclCkalloc.o tclClock.o tclCmdAH.o tclCmdIL.o tclCmdMZ.o tclCompCmds.o tclCompCmdsGR.o tclCompCmdsSZ.o tclCompExpr.o tclCompile.o tclConfig.o tclDate.o tclDictObj.o tclDisassemble.o tclEncoding.o tclEnsemble.o tclEnv.o tclEvent.o tclExecute.o tclFCmd.o tclFileName.o tclGet.o tclHash.o tclHistory.o tclIndexObj.o tclInterp.o tclIO.o tclIOCmd.o tclIORChan.o tclIORTrans.o tclIOGT.o tclIOSock.o tclIOUtil.o tclLink.o tclListObj.o tclLiteral.o tclLoad.o tclMain.o tclNamesp.o tclNotify.o tclObj.o tclOptimize.o tclPanic.o tclParse.o tclPathObj.o tclPipe.o tclPkg.o tclPkgConfig.o tclPosixStr.o tclPreserve.o tclProc.o tclRegexp.o tclResolve.o tclResult.o tclScan.o tclStringObj.o tclStrToD.o tclThread.o tclThreadAlloc.o tclThreadJoin.o tclThreadStorage.o tclStubInit.o tclTimer.o tclTrace.o tclUtf.o tclUtil.o tclVar.o tclZlib.o tclTomMathInterface.o tclUnixChan.o tclUnixEvent.o tclUnixFCmd.o tclUnixFile.o tclUnixPipe.o tclUnixSock.o tclUnixTime.o tclUnixInit.o tclUnixThrd.o tclUnixCompat.o tclUnixNotfy.o  tclOO.o tclOOBasic.o tclOOCall.o tclOODefineCmds.o tclOOInfo.o tclOOMethod.o tclOOStubInit.o tclLoadDyld.o tclMacOSXBundle.o tclMacOSXFCmd.o tclMacOSXNotify.o bn_s_mp_reverse.o bn_s_mp_mul_digs_fast.o bn_s_mp_sqr_fast.o bn_mp_add.o bn_mp_and.o bn_mp_add_d.o bn_mp_clamp.o bn_mp_clear.o bn_mp_clear_multi.o bn_mp_cmp.o bn_mp_cmp_d.o bn_mp_cmp_mag.o bn_mp_cnt_lsb.o bn_mp_copy.o bn_mp_count_bits.o bn_mp_div.o bn_mp_div_d.o bn_mp_div_2.o bn_mp_div_2d.o bn_mp_div_3.o bn_mp_exch.o bn_mp_expt_u32.o bn_mp_grow.o bn_mp_init.o bn_mp_init_copy.o bn_mp_init_multi.o bn_mp_init_set.o bn_mp_init_size.o bn_s_mp_karatsuba_mul.o bn_s_mp_karatsuba_sqr.o bn_s_mp_balance_mul.o bn_mp_lshd.o bn_mp_mod.o bn_mp_mod_2d.o bn_mp_mul.o bn_mp_mul_2.o bn_mp_mul_2d.o bn_mp_mul_d.o bn_mp_neg.o bn_mp_or.o bn_mp_radix_size.o bn_mp_radix_smap.o bn_mp_read_radix.o bn_mp_rshd.o bn_mp_set.o bn_mp_shrink.o bn_mp_sqr.o bn_mp_sqrt.o bn_mp_sub.o bn_mp_sub_d.o bn_mp_signed_rsh.o bn_mp_to_ubin.o bn_s_mp_toom_mul.o bn_s_mp_toom_sqr.o bn_mp_to_radix.o bn_mp_ubin_size.o bn_mp_xor.o bn_mp_zero.o bn_s_mp_add.o bn_s_mp_mul_digs.o bn_s_mp_sqr.o bn_s_mp_sub.o  Zadler32.o Zcompress.o Zcrc32.o Zdeflate.o Zinfback.o Zinffast.o Zinflate.o Zinftrees.o Ztrees.o Zuncompr.o Zzutil.o   -headerpad_max_install_names -Wl,-search_paths_first  -lpthread  -compatibility_version 8.6 -current_version 8.6.12 -install_name "/opt/tcl-8.6.12.ppc64/lib"/libtcl8.6.dylib -sectcreate __TEXT __info_plist Tcl-Info.plist  
    #   ld64-62.1 failed: bad offset (0x0015595D) for lo14 instruction pic-base fix-up in _BinaryScanCmd from tclBinary.o
    #   /usr/libexec/gcc/powerpc-apple-darwin8/4.0.1/libtool: internal link edit command failed
    #   make: *** [libtcl8.6.dylib] Error 1
    # So we use gcc-4.2 for the 64-bit build.
    if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
        tiger.sh gcc-4.2
    fi
    CC=gcc-4.2
else
    CC=gcc
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

CFLAGS=$(tiger.sh -mcpu -O)
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    B64="--enable-64bit"
fi

# We'll provide our own optimization flags.
sed -i '' -e 's/CFLAGS_OPTIMIZE="-Os"/CFLAGS_OPTIMIZE=""/g' unix/configure

cd unix
/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --enable-threads \
    --enable-shared \
    --enable-load \
    --disable-rpath \
    --enable-corefoundation \
    $B64 \
    CFLAGS="$CFLAGS" \
    CC="$CC"

# Note: --enable-framework violates --prefix and causes lots of things to be
# written to /Library/Frameworks/Tcl.framework.

# The original source distribution comes in a directory named 'tcl8.6.12',
# which I rename to 'tcl-8.6.12'.
# The Makefile needs to be patched to account for this:
sed -i '' -e 's|s/tcl//|s/tcl-//|' Makefile

/usr/bin/time make $(tiger.sh -j) V=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make test
fi

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
