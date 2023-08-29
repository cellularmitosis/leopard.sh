#!/bin/bash
# based on templates/build-from-source.sh v6

# Install meson on OS X Leopard / PowerPC.

package=meson
version=1.2.1
upstream=https://github.com/mesonbuild/$package/releases/download/$version/$package-$version.tar.gz
description="Open source build system"

set -e -o pipefail

pkgspec=$package-$version$ppc64
pyspec=python-3.11.2

if ! test -e /opt/$pyspec ; then
    leopard.sh $pyspec
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

pip3 install $package==$version
leopard.sh --link $pyspec

# Many thanks to the MacPorts team!
patchroot=https://raw.githubusercontent.com/macports/macports-ports/master/devel/meson/files
curl -f $patchroot/patch-meson-gcc-appleframeworks.diff | patch -p0
curl -f $patchroot/patch-meson-gnome.diff | patch -p0
curl -f $patchroot/patch-meson-search-prefix-for-cross-files.diff | patch -p0
curl -f $patchroot/patch-meson64-tiger-no-rpath-fix.diff | patch -p0

exit 0

# meson-1.2.1 doesn't detect Darwin/PowerPC ld.
if ! grep -q cctools /opt/$pyspec/lib/python3.11/site-packages/mesonbuild/linkers/detect.py ; then
cd /opt/$pyspec/lib/python3.11/site-packages
patch -p1 << 'EOF'
diff -urN meson-1.2.1.orig/mesonbuild/build.py meson-1.2.1/mesonbuild/build.py
--- meson-1.2.1.orig/mesonbuild/build.py	2023-08-07 17:54:34.000000000 -0500
+++ meson-1.2.1/mesonbuild/build.py	2023-08-28 18:40:29.136221157 -0500
@@ -132,7 +132,7 @@
 
 @lru_cache(maxsize=None)
 def get_target_macos_dylib_install_name(ld) -> str:
-    name = ['@rpath/', ld.prefix, ld.name]
+    name = [ld.prefix, ld.name]
     if ld.soversion is not None:
         name.append('.' + ld.soversion)
     name.append('.dylib')
diff -urN meson-1.2.1.orig/mesonbuild/linkers/detect.py meson-1.2.1/mesonbuild/linkers/detect.py
--- meson-1.2.1.orig/mesonbuild/linkers/detect.py	2023-07-21 15:36:13.000000000 -0500
+++ meson-1.2.1/mesonbuild/linkers/detect.py	2023-08-27 20:48:11.236634429 -0500
@@ -61,7 +61,7 @@
 
     check_args += env.coredata.get_external_link_args(for_machine, comp_class.language)
 
-    override = []  # type: T.List[str]
+    override: T.List[str] = []
     value = env.lookup_binary_entry(for_machine, comp_class.language + '_ld')
     if value is not None:
         override = comp_class.use_linker_args(value[0], comp_version)
@@ -138,7 +138,7 @@
     else:
         check_args = comp_class.LINKER_PREFIX + ['--version'] + extra_args
 
-    override = []  # type: T.List[str]
+    override: T.List[str] = []
     value = env.lookup_binary_entry(for_machine, comp_class.language + '_ld')
     if value is not None:
         override = comp_class.use_linker_args(value[0], comp_version)
@@ -186,7 +186,7 @@
 
         linker = linkers.LLVMDynamicLinker(compiler, for_machine, comp_class.LINKER_PREFIX, override, version=v)
     # first might be apple clang, second is for real gcc, the third is icc
-    elif e.endswith('(use -v to see invocation)\n') or 'macosx_version' in e or 'ld: unknown option:' in e:
+    elif e.endswith('(use -v to see invocation)\n') or 'macosx_version' in e or ': unknown option:' in e or ': unknown flag:' in e:
         if isinstance(comp_class.LINKER_PREFIX, str):
             cmd = compiler + [comp_class.LINKER_PREFIX + '-v'] + extra_args
         else:
@@ -198,7 +198,12 @@
                 v = line.split('-')[1]
                 break
         else:
-            __failed_to_detect_linker(compiler, check_args, o, e)
+            for word in newo.split():
+                if 'cctools-' in word:
+                    v = word.split('-')[1]
+                    break
+            else:
+                __failed_to_detect_linker(compiler, check_args, o, e)
         linker = linkers.AppleDynamicLinker(compiler, for_machine, comp_class.LINKER_PREFIX, override, version=v)
     elif 'GNU' in o or 'GNU' in e:
         gnu_cls: T.Type[GnuDynamicLinker]
diff -urN meson-1.2.1.orig/mesonbuild/linkers/linkers.py meson-1.2.1/mesonbuild/linkers/linkers.py
--- meson-1.2.1.orig/mesonbuild/linkers/linkers.py	2023-08-07 17:54:34.000000000 -0500
+++ meson-1.2.1/mesonbuild/linkers/linkers.py	2023-08-28 18:41:04.211146514 -0500
@@ -797,7 +797,7 @@
 
     def get_soname_args(self, env: 'Environment', prefix: str, shlib_name: str,
                         suffix: str, soversion: str, darwin_versions: T.Tuple[str, str]) -> T.List[str]:
-        install_name = ['@rpath/', prefix, shlib_name]
+        install_name = [prefix, shlib_name]
         if soversion is not None:
             install_name.append('.' + soversion)
         install_name.append('.dylib')
EOF
cd - >/dev/null
fi
