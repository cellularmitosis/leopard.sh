#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install htop on OS X Tiger / PowerPC.

package=htop
version=3.2.2
upstream=https://github.com/htop-dev/htop/releases/download/$version/htop-$version.tar.xz
description="Interactive process viewer"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

dep=macports-legacy-support-20221029$ppc64
if ! test -e /opt/$dep ; then
    tiger.sh $dep
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

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# FIXME this patch disables some functionality.  Revisit this.

patch -p1 << 'EOF'
diff -urN htop-3.2.2.orig/darwin/DarwinProcess.c htop-3.2.2/darwin/DarwinProcess.c
--- htop-3.2.2.orig/darwin/DarwinProcess.c	2023-02-04 16:51:56.000000000 -0600
+++ htop-3.2.2/darwin/DarwinProcess.c	2023-08-26 19:01:48.000000000 -0500
@@ -5,9 +5,15 @@
 in the source distribution for its full text.
 */
 
+#include <AvailabilityMacros.h>
+
 #include "darwin/DarwinProcess.h"
 
+/* libproc.h was introduced in OS X 10.5. */
+#if defined(MAC_OS_X_VERSION_10_5)
 #include <libproc.h>
+#endif
+
 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
@@ -100,6 +106,8 @@
 }
 
 static void DarwinProcess_updateExe(pid_t pid, Process* proc) {
+/* PROC_PIDPATHINFO_MAXSIZE was introduced in OS X 10.5. */
+#if defined(MAC_OS_X_VERSION_10_5)
    char path[PROC_PIDPATHINFO_MAXSIZE];
 
    int r = proc_pidpath(pid, path, sizeof(path));
@@ -107,9 +115,12 @@
       return;
 
    Process_updateExe(proc, path);
+#endif
 }
 
 static void DarwinProcess_updateCwd(pid_t pid, Process* proc) {
+/* PROC_PIDVNODEPATHINFO was introduced in OS X 10.5. */
+#if defined(MAC_OS_X_VERSION_10_5)
    struct proc_vnodepathinfo vpi;
 
    int r = proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &vpi, sizeof(vpi));
@@ -126,6 +137,7 @@
    }
 
    free_and_xStrdup(&proc->procCwd, vpi.pvi_cdir.vip_path);
+#endif
 }
 
 static void DarwinProcess_updateCmdLine(const struct kinfo_proc* k, Process* proc) {
@@ -361,6 +373,8 @@
 }
 
 void DarwinProcess_setFromLibprocPidinfo(DarwinProcess* proc, DarwinProcessList* dpl, double timeIntervalNS) {
+/* PROC_PIDTASKINFO was introduced in OS X 10.5. */
+#if defined(MAC_OS_X_VERSION_10_5)
    struct proc_taskinfo pti;
 
    if (sizeof(pti) == proc_pidinfo(proc->super.pid, PROC_PIDTASKINFO, 0, &pti, sizeof(pti))) {
@@ -395,6 +409,7 @@
       dpl->super.totalTasks += pti.pti_threadnum;
       dpl->super.runningTasks += pti.pti_numrunning;
    }
+#endif
 }
 
 /*
diff -urN htop-3.2.2.orig/darwin/DarwinProcessList.c htop-3.2.2/darwin/DarwinProcessList.c
--- htop-3.2.2.orig/darwin/DarwinProcessList.c	2023-02-04 16:51:56.000000000 -0600
+++ htop-3.2.2/darwin/DarwinProcessList.c	2023-08-26 19:13:31.000000000 -0500
@@ -8,7 +8,12 @@
 #include "darwin/DarwinProcessList.h"
 
 #include <errno.h>
+
+/* libproc.h was introduced in OS X 10.5. */
+#if defined(MAC_OS_X_VERSION_10_5)
 #include <libproc.h>
+#endif
+
 #include <stdbool.h>
 #include <stdio.h>
 #include <stdlib.h>
@@ -26,6 +31,9 @@
 #include "generic/openzfs_sysctl.h"
 #include "zfs/ZfsArcStats.h"
 
+#if !defined(MAC_OS_X_VERSION_10_5)
+extern vm_size_t vm_page_size;
+#endif
 
 static void ProcessList_getHostInfo(host_basic_info_data_t* p) {
    mach_msg_type_number_t info_size = HOST_BASIC_INFO_COUNT;
EOF

CFLAGS="$(tiger.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(tiger.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

CPPFLAGS="-I/opt/macports-legacy-support-20221029$ppc64/include/LegacySupport $CPPFLAGS"
LDFLAGS="-L/opt/macports-legacy-support-20221029$ppc64/lib $LDFLAGS"
LIBS="-lMacportsLegacySupport $LIBS"

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    --disable-maintainer-mode \
    --disable-debug \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    CPPFLAGS="$CPPFLAGS" \
    LIBS="$LIBS"

/usr/bin/time make $(tiger.sh -j) V=1

# Note: no 'make check' available.

make install

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
