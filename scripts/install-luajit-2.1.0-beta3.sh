#!/bin/bash

# Install luajit on OS X Leopard / PowerPC.

package=luajit
version=2.1.0-beta3

set -e -x -o pipefail
PATH="/opt/portable-curl/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

# if ! which -s xz ; then
#     leopard.sh xz-5.2.5
# fi

if ! test -e /opt/gcc-4.9.4 ; then
    leopard.sh gcc-4.9.4
fi

# if ! test -e /opt/libiconv-1.16 ; then
#     leopard.sh libiconv-1.16
# fi

# if ! test -e /opt/expat-2.4.3 ; then
#     leopard.sh expat-2.4.3
# fi

echo -n -e "\033]0;Installing $package-$version\007"

binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz
if curl -sSfI $LEOPARDSH_MIRROR/binpkgs/$binpkg >/dev/null 2>&1 && test -z "$LEOPARDSH_FORCE_BUILD" ; then
    cd /opt
    curl -#f $LEOPARDSH_MIRROR/binpkgs/$binpkg | gunzip | tar x
else
    srcmirror=https://luajit.org/download
    tarball=LuaJIT-$version.tar.gz

    if ! test -e ~/Downloads/$tarball ; then
        cd ~/Downloads
        curl -#fLO $srcmirror/$tarball
    fi

    cd /tmp
    rm -rf $package-$version
    tar xzf ~/Downloads/$tarball
    cd LuaJIT-$version
    patch << 'EOF'
--- Makefile	2022-01-18 02:33:49.000000000 -0600
+++ Makefile.new	2022-01-18 02:34:08.000000000 -0600
@@ -25,7 +25,7 @@
 # Change the installation path as needed. This automatically adjusts
 # the paths in src/luaconf.h, too. Note: PREFIX must be an absolute path!
 #
-export PREFIX= /usr/local
+export PREFIX= /opt/luajit-2.1.0-beta3
 export MULTILIB= lib
 ##############################################################################
EOF
    PATH="/opt/gcc-4.9.4/bin:$PATH" make $(leopard.sh -j)
fi

ln -sf /opt/$package-$version/bin/* /usr/local/bin/

# Note: luajit needs at least GCC 4.3:
# lj_arch.h:395:2: error: #error "Need at least GCC 4.3 or newer"

# Failure:
# BUILDVM   lj_vm.S
# ASM       lj_vm.o
# buildvm_ppc.dasc:326:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:455:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1755:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1773:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1781:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1789:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1797:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1805:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1813:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1821:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1829:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1837:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1845:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1853:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1861:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1869:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1877:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1886:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1895:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1904:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1913:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1921:Invalid mnemonic 'plt'
# buildvm_ppc.dasc:1930:Invalid mnemonic 'plt'
# make[1]: *** [lj_vm.o] Error 1
# make: *** [default] Error 2

# http://devpit.org/wiki/Debugging_PowerPC_ELF_Binaries
# https://reverseengineering.stackexchange.com/questions/1992/what-is-plt-got
# https://stackoverflow.com/questions/6384961/osx-gnu-assembler-problem-with-call-fooplt


# echo "BUILDVM   lj_vm.s"
# host/buildvm -m machasm -o lj_vm.s
# echo "ASM       lj_vm.o"
# :  -O2 -fomit-frame-pointer -Wall   -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -U_FORTIFY_SOURCE  -fno-stack-protector   -c -o lj_vm_dyn.o lj_vm.s
# gcc  -O2 -fomit-frame-pointer -Wall   -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -U_FORTIFY_SOURCE  -fno-stack-protector   -c -o lj_vm.o lj_vm.s


# echo "DYNASM    host/buildvm_arch.h"
# host/minilua ../dynasm/dynasm.lua   -D JIT -D FFI -D DUALNUM -D FPU -D HFABI -D VER=0 -o host/buildvm_arch.h vm_ppc.dasc
# echo "HOSTCC    host/buildvm.o"
# gcc  -O2 -fomit-frame-pointer -Wall   -I. -DLUAJIT_TARGET=LUAJIT_ARCH_ppc -DLJ_ARCH_HASFPU=1 -DLJ_ABI_SOFTFP=0  -c -o host/buildvm.o host/buildvm.c
# echo "HOSTCC    host/buildvm_asm.o"
# gcc  -O2 -fomit-frame-pointer -Wall   -I. -DLUAJIT_TARGET=LUAJIT_ARCH_ppc -DLJ_ARCH_HASFPU=1 -DLJ_ABI_SOFTFP=0  -c -o host/buildvm_asm.o host/buildvm_asm.c
# echo "HOSTCC    host/buildvm_peobj.o"
# gcc  -O2 -fomit-frame-pointer -Wall   -I. -DLUAJIT_TARGET=LUAJIT_ARCH_ppc -DLJ_ARCH_HASFPU=1 -DLJ_ABI_SOFTFP=0  -c -o host/buildvm_peobj.o host/buildvm_peobj.c
# echo "HOSTCC    host/buildvm_lib.o"
# gcc  -O2 -fomit-frame-pointer -Wall   -I. -DLUAJIT_TARGET=LUAJIT_ARCH_ppc -DLJ_ARCH_HASFPU=1 -DLJ_ABI_SOFTFP=0  -c -o host/buildvm_lib.o host/buildvm_lib.c
# echo "HOSTCC    host/buildvm_fold.o"
# gcc  -O2 -fomit-frame-pointer -Wall   -I. -DLUAJIT_TARGET=LUAJIT_ARCH_ppc -DLJ_ARCH_HASFPU=1 -DLJ_ABI_SOFTFP=0  -c -o host/buildvm_fold.o host/buildvm_fold.c
# echo "HOSTLINK  host/buildvm"
# gcc     -o host/buildvm host/buildvm.o host/buildvm_asm.o host/buildvm_peobj.o host/buildvm_lib.o host/buildvm_fold.o   
# host/buildvm -m machasm -o lj_vm.s
# host/buildvm -m ffdef -o lj_ffdef.h lib_base.c lib_math.c lib_bit.c lib_string.c lib_table.c lib_io.c lib_os.c lib_package.c lib_debug.c lib_jit.c lib_ffi.c
# host/buildvm -m bcdef -o lj_bcdef.h lib_base.c lib_math.c lib_bit.c lib_string.c lib_table.c lib_io.c lib_os.c lib_package.c lib_debug.c lib_jit.c lib_ffi.c
# host/buildvm -m folddef -o lj_folddef.h lj_opt_fold.c
# host/buildvm -m recdef -o lj_recdef.h lib_base.c lib_math.c lib_bit.c lib_string.c lib_table.c lib_io.c lib_os.c lib_package.c lib_debug.c lib_jit.c lib_ffi.c
# host/buildvm -m libdef -o lj_libdef.h lib_base.c lib_math.c lib_bit.c lib_string.c lib_table.c lib_io.c lib_os.c lib_package.c lib_debug.c lib_jit.c lib_ffi.c
# host/buildvm -m vmdef -o jit/vmdef.lua lib_base.c lib_math.c lib_bit.c lib_string.c lib_table.c lib_io.c lib_os.c lib_package.c lib_debug.c lib_jit.c lib_ffi.c

