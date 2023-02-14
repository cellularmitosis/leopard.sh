#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install llvm on OS X Tiger / PowerPC.

# From https://github.com/macports/macports-ports/blob/master/lang/llvm-3.7/Portfile:
#   llvm-3.7 was the last version to use the autoconf build system.  Newer
#   versions require cmake to build.  Cmake requires a C++11 toolchain, so
#   clang-3.7 is being kept around in order to build cmake (or its dependencies)
#   if needed on such systems.

package=llvm
version=3.7.1
upstream=https://releases.llvm.org/3.7.1/llvm-3.7.1.src.tar.xz

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

if ! test -e /opt/libffi-3.4.2 ; then
    tiger.sh libffi-3.4.2
fi

if ! type -a gcc-4.9 >/dev/null 2>&1 ; then
    tiger.sh gcc-4.9.4
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

if ! test -e /opt/python2-2.7.18 ; then
    tiger.sh python2-2.7.18
fi

if ! test -e /opt/ld64-97.17-tigerbrew ; then
    tiger.sh ld64-97.17-tigerbrew
fi
export PATH="/opt/ld64-97.17-tigerbrew/bin:$PATH"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

tiger.sh --unpack-dist cfe-3.7.1.src
mv /tmp/cfe-3.7.1.src /tmp/$package-$version/tools/clang

tiger.sh --unpack-dist libcxx-3.7.1.src
mv /tmp/libcxx-3.7.1.src /tmp/$package-$version/projects/libcxx

tiger.sh --unpack-dist libcxxabi-3.7.1.src
mv /tmp/libcxxabi-3.7.1.src /tmp/$package-$version/libcxxabi

# tiger.sh --unpack-dist polly-3.7.1.src
# mv /tmp/polly-3.7.1.src /tmp/$package-$version/tools/polly

# tiger.sh --unpack-dist clang-tools-extra-3.7.1.src
# mv /tmp/clang-tools-extra-3.7.1.src /tmp/$package-$version/tools/clang/tools/extra

# tiger.sh --unpack-dist compiler-rt-3.7.1.src
# mv /tmp/compiler-rt-3.7.1.src /tmp/$package-$version/projects/compiler-rt

# tiger.sh --unpack-dist lld-3.7.1.src
# mv /tmp/lld-3.7.1.src /tmp/$package-$version/tools/lld

# tiger.sh --unpack-dist lldb-3.7.1.src
# mv /tmp/lldb-3.7.1.src /tmp/$package-$version/tools/lldb

for pair in \
    "1006-Only-call-setpriority-PRIO_DARWIN_THREAD-0-PRIO_DARW.patch ccdf219c313120ef149adf05c6ff2da1" \
    "0002-Define-EXC_MASK_CRASH-and-MACH_EXCEPTION_CODES-if-th.patch 2acb39b26afca7f2930fd73f5f067f20" \
; do
    pfile=$(echo $pair | cut -d' ' -f1)
    sum=$(echo $pair | cut -d' ' -f2)
    url=https://raw.githubusercontent.com/macports/macports-ports/master/lang/llvm-3.7/files/$pfile
    curl --fail --silent --show-error --location --remote-name $url
    test "$(md5 -q $pfile)" = "$sum"
    patch -p1 < $pfile
done

patch -p1 << "EOF"
diff -urN llvm-3.7.1/lib/Support/CrashRecoveryContext.cpp llvm-3.7.1.patched/lib/Support/CrashRecoveryContext.cpp
--- llvm-3.7.1/lib/Support/CrashRecoveryContext.cpp	2015-06-23 04:49:53.000000000 -0500
+++ llvm-3.7.1.patched/lib/Support/CrashRecoveryContext.cpp	2022-03-19 19:17:00.000000000 -0500
@@ -332,13 +332,13 @@
 
 // FIXME: Portability.
 static void setThreadBackgroundPriority() {
-#ifdef __APPLE__
+#if defined(__APPLE__) && defined(PRIO_DARWIN_THREAD)
   setpriority(PRIO_DARWIN_THREAD, 0, PRIO_DARWIN_BG);
 #endif
 }
 
 static bool hasThreadBackgroundPriority() {
-#ifdef __APPLE__
+#if defined(__APPLE__) && defined(PRIO_DARWIN_THREAD)
   return getpriority(PRIO_DARWIN_THREAD, 0) == 1;
 #else
   return false;
EOF

CC=gcc-4.9
CXX=g++-4.9

builddir=/tmp/$pkgspec.build
rm -rf $builddir
mkdir $builddir
cd $builddir

/usr/bin/time /tmp/$package-$version/configure -C --prefix=/opt/$pkgspec \
    --with-python=/opt/python2-2.7.18/bin/python2 \
    --enable-targets=powerpc \
    --enable-optimized \
    --with-optimize-option=" -O0" \
    --disable-bindings \
    CC="$CC" \
    CXX="$CXX"

    # --enable-shared \
    # --disable-assertions
    # --with-optimize-option=" $(tiger.sh -mcpu -O)" \
    # --enable-profiling \
    # --enable-libffi

# There seems to be a Tiger-specific problem with libedit:
#   llvm[2]: Linking Release+Asserts unit test LineEditor (without symbols)
#   g++-4.9   -O0 -Wl,-dead_strip  -L/private/tmp/llvm-3.7.1.build/Release+Asserts/lib -L/private/tmp/llvm-3.7.1.build/Release+Asserts/lib   -mmacosx-version-min=10.4  -o Release+Asserts/LineEditorTests  /private/tmp/llvm-3.7.1.build/unittests/LineEditor/Release+Asserts/LineEditor.o  \
#   -lgtest -lgtest_main -lLLVMLineEditor -lLLVMSupport   -lz -lpthread -ledit -lcurses -lm 
#   ld: warning: object file compiled with -mlong-branch which is no longer needed. To remove this warning, recompile without -mlong-branch: /usr/lib/crt1.o
#   ld: warning: object file compiled with -mlong-branch which is no longer needed. To remove this warning, recompile without -mlong-branch: /opt/gcc-4.9.4/lib/gcc/powerpc-apple-darwin8.11.0/4.9.4/crt3.o
#   Undefined symbols:
#     "el_init(char const*, __sFILE*, __sFILE*, __sFILE*)", referenced from:
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#     "history_init()", referenced from:
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#     "el_set(editline*, int, ...)", referenced from:
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#     "el_end(editline*)", referenced from:
#         llvm::LineEditor::~LineEditor() in libLLVMLineEditor.a(LineEditor.o)
#     "history(history*, HistEvent*, int, ...)", referenced from:
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#         llvm::LineEditor::LineEditor(llvm::StringRef, llvm::StringRef, __sFILE*, __sFILE*, __sFILE*) in libLLVMLineEditor.a(LineEditor.o)
#         llvm::LineEditor::saveHistory()      in libLLVMLineEditor.a(LineEditor.o)
#         llvm::LineEditor::loadHistory()      in libLLVMLineEditor.a(LineEditor.o)
#         __Z7historyP7historyP9HistEventiz$non_lazy_ptr in libLLVMLineEditor.a(LineEditor.o)
#        (maybe you meant: __Z7historyP7historyP9HistEventiz$non_lazy_ptr)
#     "el_push(editline*, char*)", referenced from:
#         ElCompletionFn(editline*, int)  in libLLVMLineEditor.a(LineEditor.o)
#         ElCompletionFn(editline*, int)  in libLLVMLineEditor.a(LineEditor.o)
#     "history_end(history*)", referenced from:
#         llvm::LineEditor::~LineEditor() in libLLVMLineEditor.a(LineEditor.o)
#     "el_insertstr(editline*, char const*)", referenced from:
#         ElCompletionFn(editline*, int)  in libLLVMLineEditor.a(LineEditor.o)
#     "el_get(editline*, int, void*)", referenced from:
#         ElGetPromptFn(editline*)      in libLLVMLineEditor.a(LineEditor.o)
#         ElCompletionFn(editline*, int)  in libLLVMLineEditor.a(LineEditor.o)
#     "el_line(editline*)", referenced from:
#         ElCompletionFn(editline*, int)  in libLLVMLineEditor.a(LineEditor.o)
#   ld: symbol(s) not found
#   collect2: error: ld returned 1 exit status
#   make[2]: *** [Release+Asserts/LineEditorTests] Error 1
#   make[1]: *** [LineEditor/.makeall] Error 2
#
# I can't seem to figure this out.  For now, disable libedit.
sed -i '' -e 's/#define HAVE_LIBEDIT 1/#define HAVE_LIBEDIT 0/' include/llvm/Config/config.h

/usr/bin/time make $(tiger.sh -j) VERBOSE=1

if test -n "$TIGERSH_RUN_TESTS" ; then
    make check
fi

# Note: no 'make check' available.

make install VERBOSE=1

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
