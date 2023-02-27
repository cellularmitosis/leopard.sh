#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install x264 on OS X Tiger / PowerPC.

package=x264
version=20230128
# git clone https://code.videolan.org/videolan/x264.git
upstream=https://code.videolan.org/videolan/x264/-/archive/master/x264-master.tar.bz2
description="H.264/MPEG-4 AVC codec"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# 👇 EDIT HERE:
# dep=bar-1.0$ppc64
# if ! test -e /opt/$dep ; then
#     tiger.sh $dep
#     PATH="/opt/$dep/bin:$PATH"
# fi

# 👇 EDIT HERE:
# for dep in \
#     bar-2.1$ppc64 \
#     qux-3.4$ppc64
# do
#     if ! test -e /opt/$dep ; then
#         tiger.sh $dep
#     fi
#     CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
#     LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
#     PATH="/opt/$dep/bin:$PATH"
#     PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/$dep/lib/pkgconfig"
# done
# LIBS="-lbar -lqux"
# PKG_CONFIG_PATH="$(echo $PKG_CONFIG_PATH | sed -e 's/^://')"

# 👇 EDIT HERE:
# if ! perl -e "use Text::Unidecode" >/dev/null 2>&1 ; then
#     echo no | cpan
#     cpan Text::Unidecode
# fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

# 👇 EDIT HERE:
# if test -z "$ppc64" -a "$(tiger.sh --cpu)" = "g5" ; then
#     # Fails during a 32-bit build on a G5 machine,
#     # so we instead install the g4e binpkg in that case.
#     if tiger.sh --install-binpkg $pkgspec tiger.g4e ; then
#         exit 0
#     fi
# else
#     if tiger.sh --install-binpkg $pkgspec ; then
#         exit 0
#     fi
# fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

# 👇 EDIT HERE:
# if ! type -a gcc-4.2 >/dev/null 2>&1 ; then
#     tiger.sh gcc-4.2
# fi

# 👇 EDIT HERE:
if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
fi

# 👇 EDIT HERE:
# if ! type -a gcc-10.3 >/dev/null 2>&1 ; then
#     tiger.sh gcc-10.3
# fi

# 👇 EDIT HERE:
# if ! type -a pkg-config >/dev/null 2>&1 ; then
#     tiger.sh pkg-config-0.29.2
# fi
# export PATH="/opt/pkg-config-0.29.2/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# x264's endian appears to be broken.
patch -p0 << 'EOF'
--- configure	2023-02-26 12:32:58.000000000 -0900
+++ configure.patched	2023-02-26 12:48:09.000000000 -0900
@@ -1033,18 +1033,7 @@
 define STACK_ALIGNMENT $stack_alignment
 ASFLAGS="$ASFLAGS -DSTACK_ALIGNMENT=$stack_alignment"
 
-# skip endianness check for Intel Compiler and MSVS, as all supported platforms are little. each have flags that will cause the check to fail as well
-CPU_ENDIAN="little-endian"
-if [ $compiler = GNU ]; then
-    echo "int i[2] = {0x42494745,0}; double f[2] = {0x1.0656e6469616ep+102,0};" > conftest.c
-    $CC $CFLAGS -fno-lto conftest.c -c -o conftest.o 2>/dev/null || die "endian test failed"
-    if (${STRINGS} -a conftest.o | grep -q BIGE) && (${STRINGS} -a conftest.o | grep -q FPendian) ; then
-        define WORDS_BIGENDIAN
-        CPU_ENDIAN="big-endian"
-    elif !(${STRINGS} -a conftest.o | grep -q EGIB && ${STRINGS} -a conftest.o | grep -q naidnePF) ; then
-        die "endian test failed"
-    fi
-fi
+CPU_ENDIAN="big-endian"
 
 if [ "$cli_libx264" = "system" -a "$shared" != "yes" ] ; then
     [ "$static" = "yes" ] && die "Option --system-libx264 can not be used together with --enable-static"
EOF

# The build fails with:
#   In file included from ./extras/cl_platform.h:348,
#                    from ./extras/cl.h:27,
#                    from ./common/opencl.h:31,
#                    from ./common/common.h:119,
#                    from common/ppc/mc.c:27:
#   /usr/lib/gcc/powerpc-apple-darwin9/4.0.1/include/altivec.h:44:2: warning: #warning Ignoring <altivec.h> because "-faltivec" specified
#   common/ppc/mc.c: In function 'pixel_avg2_w8_altivec':
#   common/ppc/mc.c:69: warning: implicit declaration of function 'vec_xxpermdi'
#   common/ppc/mc.c:69: error: AltiVec argument passed to unprototyped function
#   common/ppc/mc.c: In function 'mc_chroma_8xh_altivec':
#   common/ppc/mc.c:609: error: AltiVec argument passed to unprototyped function
#   common/ppc/mc.c:610: error: AltiVec argument passed to unprototyped function
#   common/ppc/mc.c:647: error: AltiVec argument passed to unprototyped function
#   common/ppc/mc.c:648: error: AltiVec argument passed to unprototyped function
#   common/ppc/mc.c: In function 'x264_hpel_filter_altivec':
#   common/ppc/mc.c:828: warning: implicit declaration of function 'vec_splats'
#   common/ppc/mc.c:828: error: incompatible types in assignment
#   common/ppc/mc.c:829: error: incompatible types in assignment
#   common/ppc/mc.c:830: error: incompatible types in assignment
#   common/ppc/mc.c:831: error: incompatible types in assignment
#   common/ppc/mc.c:832: error: incompatible types in assignment
#   common/ppc/mc.c:833: error: incompatible types in assignment
#
# The MacPorts team has a patch (patch-x264-older-ppc-code.diff), but it no longer
# applies cleanly against HEAD.
# The commit which broke this file was 303c484ec828ed0d8bfe743500e70314d026c3bd.
# The previous, working commit was ca5408b13cf0e58a7505051861f20a63a7a6aec1.
# Here's a diff of ca5408b1 against HEAD:
cd common/ppc
patch -p0 << 'EOF'
--- quant.c	2023-02-26 16:46:20.417458251 -0600
+++ quant.c.ca5408b1	2023-02-26 16:45:42.804020441 -0600
@@ -1,7 +1,7 @@
 /*****************************************************************************
  * quant.c: ppc quantization
  *****************************************************************************
- * Copyright (C) 2007-2023 x264 project
+ * Copyright (C) 2007-2018 x264 project
  *
  * Authors: Guillaume Poirier <gpoirier@mplayerhq.hu>
  *
@@ -39,8 +39,8 @@
     biasvB = vec_ld((idx1), bias);                                  \
     mskA = vec_cmplt(temp1v, zero_s16v);                            \
     mskB = vec_cmplt(temp2v, zero_s16v);                            \
-    coefvA = (vec_u16_t)vec_abs( temp1v );                          \
-    coefvB = (vec_u16_t)vec_abs( temp2v );                          \
+    coefvA = (vec_u16_t)vec_max(vec_sub(zero_s16v, temp1v), temp1v);\
+    coefvB = (vec_u16_t)vec_max(vec_sub(zero_s16v, temp2v), temp2v);\
     coefvA = vec_adds(coefvA, biasvA);                              \
     coefvB = vec_adds(coefvB, biasvB);                              \
     multEvenvA = vec_mule(coefvA, mfvA);                            \
@@ -51,12 +51,8 @@
     multOddvA = vec_sr(multOddvA, i_qbitsv);                        \
     multEvenvB = vec_sr(multEvenvB, i_qbitsv);                      \
     multOddvB = vec_sr(multOddvB, i_qbitsv);                        \
-    temp1v = (vec_s16_t) vec_packs( multEvenvA, multOddvA );        \
-    tmpv = xxpermdi( temp1v, temp1v, 2 );                           \
-    temp1v = vec_mergeh( temp1v, tmpv );                            \
-    temp2v = (vec_s16_t) vec_packs( multEvenvB, multOddvB );        \
-    tmpv = xxpermdi( temp2v, temp2v, 2 );                           \
-    temp2v = vec_mergeh( temp2v, tmpv );                            \
+    temp1v = (vec_s16_t) vec_packs(vec_mergeh(multEvenvA, multOddvA), vec_mergel(multEvenvA, multOddvA)); \
+    temp2v = (vec_s16_t) vec_packs(vec_mergeh(multEvenvB, multOddvB), vec_mergel(multEvenvB, multOddvB)); \
     temp1v = vec_xor(temp1v, mskA);                                 \
     temp2v = vec_xor(temp2v, mskB);                                 \
     temp1v = vec_adds(temp1v, vec_and(mskA, one));                  \
@@ -70,7 +66,7 @@
 {
     LOAD_ZERO;
     vector bool short mskA;
-    vec_u32_t i_qbitsv = vec_splats( (uint32_t)16 );
+    vec_u32_t i_qbitsv;
     vec_u16_t coefvA;
     vec_u32_t multEvenvA, multOddvA;
     vec_u16_t mfvA;
@@ -84,212 +80,14 @@
     vec_u16_t mfvB;
     vec_u16_t biasvB;
 
-    vec_s16_t temp1v, temp2v, tmpv;
-
-    QUANT_16_U( 0, 16 );
-    return vec_any_ne(nz, zero_s16v);
-}
-
-int x264_quant_4x4x4_altivec( dctcoef dcta[4][16], udctcoef mf[16], udctcoef bias[16] )
-{
-    LOAD_ZERO;
-    vec_u32_t i_qbitsv = vec_splats( (uint32_t)16 );
-    vec_s16_t one = vec_splat_s16( 1 );
-    vec_s16_t nz0, nz1, nz2, nz3;
-
-    vector bool short mskA0;
-    vec_u16_t coefvA0;
-    vec_u32_t multEvenvA0, multOddvA0;
-    vec_u16_t mfvA0;
-    vec_u16_t biasvA0;
-    vector bool short mskB0;
-    vec_u16_t coefvB0;
-    vec_u32_t multEvenvB0, multOddvB0;
-    vec_u16_t mfvB0;
-    vec_u16_t biasvB0;
-
-    vector bool short mskA1;
-    vec_u16_t coefvA1;
-    vec_u32_t multEvenvA1, multOddvA1;
-    vec_u16_t mfvA1;
-    vec_u16_t biasvA1;
-    vector bool short mskB1;
-    vec_u16_t coefvB1;
-    vec_u32_t multEvenvB1, multOddvB1;
-    vec_u16_t mfvB1;
-    vec_u16_t biasvB1;
-
-    vector bool short mskA2;
-    vec_u16_t coefvA2;
-    vec_u32_t multEvenvA2, multOddvA2;
-    vec_u16_t mfvA2;
-    vec_u16_t biasvA2;
-    vector bool short mskB2;
-    vec_u16_t coefvB2;
-    vec_u32_t multEvenvB2, multOddvB2;
-    vec_u16_t mfvB2;
-    vec_u16_t biasvB2;
-
-    vector bool short mskA3;
-    vec_u16_t coefvA3;
-    vec_u32_t multEvenvA3, multOddvA3;
-    vec_u16_t mfvA3;
-    vec_u16_t biasvA3;
-    vector bool short mskB3;
-    vec_u16_t coefvB3;
-    vec_u32_t multEvenvB3, multOddvB3;
-    vec_u16_t mfvB3;
-    vec_u16_t biasvB3;
-
     vec_s16_t temp1v, temp2v;
-    vec_s16_t tmpv0;
-    vec_s16_t tmpv1;
 
-    dctcoef *dct0 = dcta[0];
-    dctcoef *dct1 = dcta[1];
-    dctcoef *dct2 = dcta[2];
-    dctcoef *dct3 = dcta[3];
-
-    temp1v = vec_ld( 0,  dct0 );
-    temp2v = vec_ld( 16, dct0 );
-    mfvA0 = vec_ld( 0,  mf );
-    mfvB0 = vec_ld( 16, mf );
-    biasvA0 = vec_ld( 0,  bias );
-    biasvB0 = vec_ld( 16, bias );
-    mskA0 = vec_cmplt( temp1v, zero_s16v );
-    mskB0 = vec_cmplt( temp2v, zero_s16v );
-    coefvA0 = (vec_u16_t)vec_abs( temp1v );
-    coefvB0 = (vec_u16_t)vec_abs( temp2v );
-    temp1v = vec_ld( 0,  dct1 );
-    temp2v = vec_ld( 16, dct1 );
-    mfvA1 = vec_ld( 0,  mf );
-    mfvB1 = vec_ld( 16, mf );
-    biasvA1 = vec_ld( 0,  bias );
-    biasvB1 = vec_ld( 16, bias );
-    mskA1 = vec_cmplt( temp1v, zero_s16v );
-    mskB1 = vec_cmplt( temp2v, zero_s16v );
-    coefvA1 = (vec_u16_t)vec_abs( temp1v );
-    coefvB1 = (vec_u16_t)vec_abs( temp2v );
-    temp1v = vec_ld( 0,  dct2 );
-    temp2v = vec_ld( 16, dct2 );
-    mfvA2 = vec_ld( 0,  mf );
-    mfvB2 = vec_ld( 16, mf );
-    biasvA2 = vec_ld( 0,  bias );
-    biasvB2 = vec_ld( 16, bias );
-    mskA2 = vec_cmplt( temp1v, zero_s16v );
-    mskB2 = vec_cmplt( temp2v, zero_s16v );
-    coefvA2 = (vec_u16_t)vec_abs( temp1v );
-    coefvB2 = (vec_u16_t)vec_abs( temp2v );
-    temp1v = vec_ld( 0,  dct3 );
-    temp2v = vec_ld( 16, dct3 );
-    mfvA3 = vec_ld( 0,  mf );
-    mfvB3 = vec_ld( 16, mf );
-    biasvA3 = vec_ld( 0,  bias );
-    biasvB3 = vec_ld( 16, bias );
-    mskA3 = vec_cmplt( temp1v, zero_s16v );
-    mskB3 = vec_cmplt( temp2v, zero_s16v );
-    coefvA3 = (vec_u16_t)vec_abs( temp1v );
-    coefvB3 = (vec_u16_t)vec_abs( temp2v );
-
-    coefvA0 = vec_adds( coefvA0, biasvA0 );
-    coefvB0 = vec_adds( coefvB0, biasvB0 );
-    coefvA1 = vec_adds( coefvA1, biasvA1 );
-    coefvB1 = vec_adds( coefvB1, biasvB1 );
-    coefvA2 = vec_adds( coefvA2, biasvA2 );
-    coefvB2 = vec_adds( coefvB2, biasvB2 );
-    coefvA3 = vec_adds( coefvA3, biasvA3 );
-    coefvB3 = vec_adds( coefvB3, biasvB3 );
-
-    multEvenvA0 = vec_mule( coefvA0, mfvA0 );
-    multOddvA0  = vec_mulo( coefvA0, mfvA0 );
-    multEvenvB0 = vec_mule( coefvB0, mfvB0 );
-    multOddvB0  = vec_mulo( coefvB0, mfvB0 );
-    multEvenvA0 = vec_sr( multEvenvA0, i_qbitsv );
-    multOddvA0  = vec_sr( multOddvA0,  i_qbitsv );
-    multEvenvB0 = vec_sr( multEvenvB0, i_qbitsv );
-    multOddvB0  = vec_sr( multOddvB0,  i_qbitsv );
-    temp1v = (vec_s16_t)vec_packs( multEvenvA0, multOddvA0 );
-    temp2v = (vec_s16_t)vec_packs( multEvenvB0, multOddvB0 );
-    tmpv0 = xxpermdi( temp1v, temp1v, 2 );
-    tmpv1 = xxpermdi( temp2v, temp2v, 2 );
-    temp1v = vec_mergeh( temp1v, tmpv0 );
-    temp2v = vec_mergeh( temp2v, tmpv1 );
-    temp1v = vec_xor( temp1v, mskA0 );
-    temp2v = vec_xor( temp2v, mskB0 );
-    temp1v = vec_adds( temp1v, vec_and( mskA0, one ) );
-    temp2v = vec_adds( temp2v, vec_and( mskB0, one ) );
-    vec_st( temp1v, 0,  dct0 );
-    vec_st( temp2v, 16, dct0 );
-    nz0 = vec_or( temp1v, temp2v );
-
-    multEvenvA1 = vec_mule( coefvA1, mfvA1 );
-    multOddvA1  = vec_mulo( coefvA1, mfvA1 );
-    multEvenvB1 = vec_mule( coefvB1, mfvB1 );
-    multOddvB1  = vec_mulo( coefvB1, mfvB1 );
-    multEvenvA1 = vec_sr( multEvenvA1, i_qbitsv );
-    multOddvA1  = vec_sr( multOddvA1,  i_qbitsv );
-    multEvenvB1 = vec_sr( multEvenvB1, i_qbitsv );
-    multOddvB1  = vec_sr( multOddvB1,  i_qbitsv );
-    temp1v = (vec_s16_t)vec_packs( multEvenvA1, multOddvA1 );
-    temp2v = (vec_s16_t)vec_packs( multEvenvB1, multOddvB1 );
-    tmpv0 = xxpermdi( temp1v, temp1v, 2 );
-    tmpv1 = xxpermdi( temp2v, temp2v, 2 );
-    temp1v = vec_mergeh( temp1v, tmpv0 );
-    temp2v = vec_mergeh( temp2v, tmpv1 );
-    temp1v = vec_xor( temp1v, mskA1 );
-    temp2v = vec_xor( temp2v, mskB1 );
-    temp1v = vec_adds( temp1v, vec_and( mskA1, one ) );
-    temp2v = vec_adds( temp2v, vec_and( mskB1, one ) );
-    vec_st( temp1v, 0,  dct1 );
-    vec_st( temp2v, 16, dct1 );
-    nz1 = vec_or( temp1v, temp2v );
-
-    multEvenvA2 = vec_mule( coefvA2, mfvA2 );
-    multOddvA2  = vec_mulo( coefvA2, mfvA2 );
-    multEvenvB2 = vec_mule( coefvB2, mfvB2 );
-    multOddvB2  = vec_mulo( coefvB2, mfvB2 );
-    multEvenvA2 = vec_sr( multEvenvA2, i_qbitsv );
-    multOddvA2  = vec_sr( multOddvA2,  i_qbitsv );
-    multEvenvB2 = vec_sr( multEvenvB2, i_qbitsv );
-    multOddvB2  = vec_sr( multOddvB2,  i_qbitsv );
-    temp1v = (vec_s16_t)vec_packs( multEvenvA2, multOddvA2 );
-    temp2v = (vec_s16_t)vec_packs( multEvenvB2, multOddvB2 );
-    tmpv0 = xxpermdi( temp1v, temp1v, 2 );
-    tmpv1 = xxpermdi( temp2v, temp2v, 2 );
-    temp1v = vec_mergeh( temp1v, tmpv0 );
-    temp2v = vec_mergeh( temp2v, tmpv1 );
-    temp1v = vec_xor( temp1v, mskA2 );
-    temp2v = vec_xor( temp2v, mskB2 );
-    temp1v = vec_adds( temp1v, vec_and( mskA2, one ) );
-    temp2v = vec_adds( temp2v, vec_and( mskB2, one ) );
-    vec_st( temp1v, 0,  dct2 );
-    vec_st( temp2v, 16, dct2 );
-    nz2 = vec_or( temp1v, temp2v );
-
-    multEvenvA3 = vec_mule( coefvA3, mfvA3 );
-    multOddvA3  = vec_mulo( coefvA3, mfvA3 );
-    multEvenvB3 = vec_mule( coefvB3, mfvB3 );
-    multOddvB3  = vec_mulo( coefvB3, mfvB3 );
-    multEvenvA3 = vec_sr( multEvenvA3, i_qbitsv );
-    multOddvA3  = vec_sr( multOddvA3,  i_qbitsv );
-    multEvenvB3 = vec_sr( multEvenvB3, i_qbitsv );
-    multOddvB3  = vec_sr( multOddvB3,  i_qbitsv );
-    temp1v = (vec_s16_t)vec_packs( multEvenvA3, multOddvA3 );
-    temp2v = (vec_s16_t)vec_packs( multEvenvB3, multOddvB3 );
-    tmpv0 = xxpermdi( temp1v, temp1v, 2 );
-    tmpv1 = xxpermdi( temp2v, temp2v, 2 );
-    temp1v = vec_mergeh( temp1v, tmpv0 );
-    temp2v = vec_mergeh( temp2v, tmpv1 );
-    temp1v = vec_xor( temp1v, mskA3 );
-    temp2v = vec_xor( temp2v, mskB3 );
-    temp1v = vec_adds( temp1v, vec_and( mskA3, one ) );
-    temp2v = vec_adds( temp2v, vec_and( mskB3, one ) );
-    vec_st( temp1v, 0,  dct3 );
-    vec_st( temp2v, 16, dct3 );
-    nz3 = vec_or( temp1v, temp2v );
+    vec_u32_u qbits_u;
+    qbits_u.s[0]=16;
+    i_qbitsv = vec_splat(qbits_u.v, 0);
 
-    return (vec_any_ne( nz0, zero_s16v ) << 0) | (vec_any_ne( nz1, zero_s16v ) << 1) |
-           (vec_any_ne( nz2, zero_s16v ) << 2) | (vec_any_ne( nz3, zero_s16v ) << 3);
+    QUANT_16_U( 0, 16 );
+    return vec_any_ne(nz, zero_s16v);
 }
 
 // DC quant of a whole 4x4 block, unrolled 2x and "pre-scheduled"
@@ -341,9 +139,17 @@
     vec_u16_t mfv;
     vec_u16_t biasv;
 
-    mfv = vec_splats( (uint16_t)mf );
-    i_qbitsv = vec_splats( (uint32_t) 16 );
-    biasv = vec_splats( (uint16_t)bias );
+    vec_u16_u mf_u;
+    mf_u.s[0]=mf;
+    mfv = vec_splat( mf_u.v, 0 );
+
+    vec_u32_u qbits_u;
+    qbits_u.s[0]=16;
+    i_qbitsv = vec_splat(qbits_u.v, 0);
+
+    vec_u16_u bias_u;
+    bias_u.s[0]=bias;
+    biasv = vec_splat(bias_u.v, 0);
 
     QUANT_16_U_DC( 0, 16 );
     return vec_any_ne(nz, zero_s16v);
@@ -378,17 +184,25 @@
     vec_u32_t multEvenvA, multOddvA;
     vec_s16_t one = vec_splat_s16(1);
     vec_s16_t nz = zero_s16v;
-    static const vec_s16_t mask2 = CV(-1, -1, -1, -1,  0, 0, 0, 0);
 
     vec_s16_t temp1v, temp2v;
 
     vec_u16_t mfv;
     vec_u16_t biasv;
 
-    mfv = vec_splats( (uint16_t)mf );
-    i_qbitsv = vec_splats( (uint32_t) 16 );
-    biasv = vec_splats( (uint16_t)bias );
+    vec_u16_u mf_u;
+    mf_u.s[0]=mf;
+    mfv = vec_splat( mf_u.v, 0 );
+
+    vec_u32_u qbits_u;
+    qbits_u.s[0]=16;
+    i_qbitsv = vec_splat(qbits_u.v, 0);
+
+    vec_u16_u bias_u;
+    bias_u.s[0]=bias;
+    biasv = vec_splat(bias_u.v, 0);
 
+    static const vec_s16_t mask2 = CV(-1, -1, -1, -1,  0, 0, 0, 0);
     QUANT_4_U_DC(0);
     return vec_any_ne(vec_and(nz, mask2), zero_s16v);
 }
@@ -411,9 +225,11 @@
     vec_u16_t mfvB;
     vec_u16_t biasvB;
 
-    vec_s16_t temp1v, temp2v, tmpv;
+    vec_s16_t temp1v, temp2v;
 
-    i_qbitsv = vec_splats( (uint32_t)16 );
+    vec_u32_u qbits_u;
+    qbits_u.s[0]=16;
+    i_qbitsv = vec_splat(qbits_u.v, 0);
 
     for( int i = 0; i < 4; i++ )
         QUANT_16_U( i*2*16, i*2*16+16 );
@@ -429,9 +245,8 @@
                                                                      \
     multEvenvA = vec_mule(dctv, mfv);                                \
     multOddvA = vec_mulo(dctv, mfv);                                 \
-    dctv = (vec_s16_t) vec_packs( multEvenvA, multOddvA );           \
-    tmpv = xxpermdi( dctv, dctv, 2 );                                \
-    dctv = vec_mergeh( dctv, tmpv );                                 \
+    dctv = (vec_s16_t) vec_packs(vec_mergeh(multEvenvA, multOddvA),  \
+                                 vec_mergel(multEvenvA, multOddvA)); \
     dctv = vec_sl(dctv, i_qbitsv);                                   \
     vec_st(dctv, 8*y, dct);                                          \
 }
@@ -473,7 +288,7 @@
     int i_mf = i_qp%6;
     int i_qbits = i_qp/6 - 4;
 
-    vec_s16_t dctv, tmpv;
+    vec_s16_t dctv;
     vec_s16_t dct1v, dct2v;
     vec_s32_t mf1v, mf2v;
     vec_s16_t mfv;
@@ -483,7 +298,9 @@
     if( i_qbits >= 0 )
     {
         vec_u16_t i_qbitsv;
-        i_qbitsv = vec_splats( (uint16_t) i_qbits );
+        vec_u16_u qbits_u;
+        qbits_u.s[0]=i_qbits;
+        i_qbitsv = vec_splat(qbits_u.v, 0);
 
         for( int y = 0; y < 4; y+=2 )
             DEQUANT_SHL();
@@ -493,13 +310,19 @@
         const int f = 1 << (-i_qbits-1);
 
         vec_s32_t fv;
-        fv = vec_splats( f );
+        vec_u32_u f_u;
+        f_u.s[0]=f;
+        fv = (vec_s32_t)vec_splat(f_u.v, 0);
 
         vec_u32_t i_qbitsv;
-        i_qbitsv = vec_splats( (uint32_t)-i_qbits );
+        vec_u32_u qbits_u;
+        qbits_u.s[0]=-i_qbits;
+        i_qbitsv = vec_splat(qbits_u.v, 0);
 
         vec_u32_t sixteenv;
-        sixteenv = vec_splats( (uint32_t)16 );
+        vec_u32_u sixteen_u;
+        sixteen_u.s[0]=16;
+        sixteenv = vec_splat(sixteen_u.v, 0);
 
         for( int y = 0; y < 4; y+=2 )
             DEQUANT_SHR();
@@ -511,7 +334,7 @@
     int i_mf = i_qp%6;
     int i_qbits = i_qp/6 - 6;
 
-    vec_s16_t dctv, tmpv;
+    vec_s16_t dctv;
     vec_s16_t dct1v, dct2v;
     vec_s32_t mf1v, mf2v;
     vec_s16_t mfv;
@@ -521,7 +344,9 @@
     if( i_qbits >= 0 )
     {
         vec_u16_t i_qbitsv;
-        i_qbitsv = vec_splats((uint16_t)i_qbits );
+        vec_u16_u qbits_u;
+        qbits_u.s[0]=i_qbits;
+        i_qbitsv = vec_splat(qbits_u.v, 0);
 
         for( int y = 0; y < 16; y+=2 )
             DEQUANT_SHL();
@@ -531,13 +356,19 @@
         const int f = 1 << (-i_qbits-1);
 
         vec_s32_t fv;
-        fv = vec_splats( f );
+        vec_u32_u f_u;
+        f_u.s[0]=f;
+        fv = (vec_s32_t)vec_splat(f_u.v, 0);
 
         vec_u32_t i_qbitsv;
-        i_qbitsv = vec_splats( (uint32_t)-i_qbits );
+        vec_u32_u qbits_u;
+        qbits_u.s[0]=-i_qbits;
+        i_qbitsv = vec_splat(qbits_u.v, 0);
 
         vec_u32_t sixteenv;
-        sixteenv = vec_splats( (uint32_t)16 );
+        vec_u32_u sixteen_u;
+        sixteen_u.s[0]=16;
+        sixteenv = vec_splat(sixteen_u.v, 0);
 
         for( int y = 0; y < 16; y+=2 )
             DEQUANT_SHR();
EOF
cd -

# 👇 EDIT HERE:
CC=gcc-4.9
CXX=g++-4.9

# 👇 EDIT HERE:
CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(tiger.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

# 👇 EDIT HERE:
/usr/bin/time ./configure --prefix=/opt/$pkgspec \
    --enable-shared

    # --disable-dependency-tracking \
    # --disable-maintainer-mode \
    # --disable-debug \
    # CFLAGS="$CFLAGS" \
    # CXXFLAGS="$CXXFLAGS" \
    # --with-bar=/opt/bar-1.0$ppc64 \
    # --with-bar-prefix=/opt/bar-1.0$ppc64 \
    # LDFLAGS="$LDFLAGS" \
    # CPPFLAGS="$CPPFLAGS" \
    # LIBS="$LIBS" \
    # CC="$CC" \
    # CXX="$CXX" \
    # PKG_CONFIG=/opt/pkg-config-0.29.2/bin/pkg-config \
    # PKG_CONFIG_PATH="/opt/libfoo-1.0$ppc64/lib/pkgconfig:/opt/libbar-1.0$ppc64/lib/pkgconfig" \

/usr/bin/time make $(tiger.sh -j) V=1

# 👇 EDIT HERE:
if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

# 👇 EDIT HERE:
# if test -n "$TIGERSH_RUN_BROKEN_TESTS" ; then
#     make check
# fi

# 👇 EDIT HERE:
# if test -n "$TIGERSH_RUN_LONG_TESTS" ; then
#     make check
# fi

# 👇 EDIT HERE:
# Note: no 'make check' available.

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
