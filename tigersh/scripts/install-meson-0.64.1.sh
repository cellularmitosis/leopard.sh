#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install meson on OS X Tiger / PowerPC.

package=meson
version=0.64.1
upstream=https://github.com/mesonbuild/$package/releases/download/$version/$package-$version.tar.gz
description="Open source build system"

set -e -o pipefail

pkgspec=$package-$version
pyspec=python-3.11.2

if ! test -e /opt/$pyspec ; then
    tiger.sh $pyspec
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

pip3 install $package==$version
tiger.sh --link $pyspec

cd /opt/$pyspec/lib/python3.11/site-packages

# Many thanks to the MacPorts team!
patchroot=https://raw.githubusercontent.com/macports/macports-ports/master/devel/meson/files
curl -f $patchroot/patch-meson-gcc-appleframeworks.diff | patch -p0
curl -f $patchroot/patch-meson-gnome.diff | patch -p0
curl -f $patchroot/patch-meson64-tiger-no-rpath-fix.diff | patch -p0

# disable the rpath shenanigans
patch -p0 << 'EOF'
--- mesonbuild/backend/backends.py.orig	2023-08-28 23:12:56.000000000 -0500
+++ mesonbuild/backend/backends.py	2023-08-28 23:14:13.000000000 -0500
@@ -766,6 +766,7 @@
     # This may take other types
     def determine_rpath_dirs(self, target: T.Union[build.BuildTarget, build.CustomTarget, build.CustomTargetIndex]
                              ) -> T.Tuple[str, ...]:
+        return OrderedSet()
         result: OrderedSet[str]
         if self.environment.coredata.get_option(OptionKey('layout')) == 'mirror':
             # Need a copy here
EOF

patch -p0 << 'EOF'
--- mesonbuild/scripts/depfixer.py.orig	2023-08-28 23:48:25.000000000 -0500
+++ mesonbuild/scripts/depfixer.py	2023-08-28 23:51:42.000000000 -0500
@@ -409,12 +409,21 @@
     return result
 
 def fix_darwin(fname: str, new_rpath: str, final_path: str, install_name_mappings: T.Dict[str, str]) -> None:
+    print()
+    print("*** fix_darwin")
+    print("fname %s" % fname)
+    print("new_rpath %s" % new_rpath)
+    print("final_path %s" % final_path)
+    print("install_name_mappings %s" % install_name_mappings)
+    print()
     try:
         rpaths = get_darwin_rpaths_to_remove(fname)
     except subprocess.CalledProcessError:
         # Otool failed, which happens when invoked on a
         # non-executable target. Just return.
         return
+    print("get_darwin_rpaths_to_remove %s" % rpaths)
+    print()
     try:
         args = []
         if rpaths:
@@ -452,6 +461,7 @@
             for old, new in install_name_mappings.items():
                 args += ['-change', old, new]
         if args:
+            print("subprocess %s" % (['install_name_tool', fname] + args))
             subprocess.check_call(['install_name_tool', fname] + args,
                                   stdout=subprocess.DEVNULL,
                                   stderr=subprocess.DEVNULL)
EOF

patch -p0 << 'EOF'
--- mesonbuild/linkers/linkers.py.orig	2023-08-28 23:32:42.000000000 -0500
+++ mesonbuild/linkers/linkers.py	2023-08-28 23:34:29.000000000 -0500
@@ -792,7 +792,8 @@
 
     def get_soname_args(self, env: 'Environment', prefix: str, shlib_name: str,
                         suffix: str, soversion: str, darwin_versions: T.Tuple[str, str]) -> T.List[str]:
-        install_name = ['@loader_path/', prefix, shlib_name]
+        #install_name = ['@loader_path/', prefix, shlib_name]
+        install_name = [prefix, shlib_name]
         if soversion is not None:
             install_name.append('.' + soversion)
         install_name.append('.dylib')
@@ -812,7 +813,8 @@
         # https://stackoverflow.com/q/26280738
         origin_placeholder = '@loader_path'
         processed_rpaths = prepare_rpaths(rpath_paths, build_dir, from_dir)
-        all_paths = mesonlib.OrderedSet([os.path.join(origin_placeholder, p) for p in processed_rpaths])
+        #all_paths = mesonlib.OrderedSet([os.path.join(origin_placeholder, p) for p in processed_rpaths])
+        all_paths = mesonlib.OrderedSet(processed_rpaths)
         if build_rpath != '':
             all_paths.add(build_rpath)
         #KEN for rp in all_paths:
EOF

cd - >/dev/null

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
