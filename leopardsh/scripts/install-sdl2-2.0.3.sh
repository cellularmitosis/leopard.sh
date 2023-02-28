#!/bin/bash
# based on templates/build-from-source.sh v6

# Install sdl2 on OS X Leopard / PowerPC.

package=sdl2
version=2.0.3
upstream=https://www.libsdl.org/release/SDL2-$version.tar.gz
description="Simple Direct Media Layer"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64


echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

if leopard.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    leopard.sh xcode-3.1.4
fi

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Thanks to Thomas Bernard.
# See https://forums.libsdl.org/viewtopic.php?p=49066
# See https://gist.github.com/miniupnp/a8f474c504eaa3ad9135
patch -p1 << 'PATCH_EOF'
Only in SDL2-2.0.3: Makefile
Only in SDL2-2.0.3: Makefile.rules
Only in SDL2-2.0.3: build
Only in SDL2-2.0.3: config.log
Only in SDL2-2.0.3: config.status
diff -ru SDL2-2.0.3-orig/include/SDL_config.h SDL2-2.0.3/include/SDL_config.h
--- SDL2-2.0.3-orig/include/SDL_config.h	2014-03-16 03:31:42.000000000 +0100
+++ SDL2-2.0.3/include/SDL_config.h	2015-10-28 16:11:01.000000000 +0100
@@ -1,3 +1,4 @@
+/* include/SDL_config.h.  Generated from SDL_config.h.in by configure.  */
 /*
   Simple DirectMedia Layer
   Copyright (C) 1997-2014 Sam Lantinga <slouken@libsdl.org>
@@ -22,34 +23,312 @@
 #ifndef _SDL_config_h
 #define _SDL_config_h
 
-#include "SDL_platform.h"
-
 /**
- *  \file SDL_config.h
+ *  \file SDL_config.h.in
+ *
+ *  This is a set of defines to configure the SDL features
  */
 
-/* Add any platform that doesn't build using the configure system. */
-#ifdef USING_PREMAKE_CONFIG_H
-#include "SDL_config_premake.h"
-#elif defined(__WIN32__)
-#include "SDL_config_windows.h"
-#elif defined(__WINRT__)
-#include "SDL_config_winrt.h"
-#elif defined(__MACOSX__)
-#include "SDL_config_macosx.h"
-#elif defined(__IPHONEOS__)
-#include "SDL_config_iphoneos.h"
-#elif defined(__ANDROID__)
-#include "SDL_config_android.h"
-#elif defined(__PSP__)
-#include "SDL_config_psp.h"
+/* General platform specific identifiers */
+#include "SDL_platform.h"
+
+/* Make sure that this isn't included by Visual C++ */
+#ifdef _MSC_VER
+#error You should run hg revert SDL_config.h 
+#endif
+
+/* C language features */
+/* #undef const */
+/* #undef inline */
+/* #undef volatile */
+
+/* C datatypes */
+#ifdef __LP64__
+#define SIZEOF_VOIDP 8
 #else
-/* This is a minimal configuration just to get SDL running on new platforms */
-#include "SDL_config_minimal.h"
-#endif /* platform config */
+#define SIZEOF_VOIDP 4
+#endif
+/* #undef HAVE_GCC_ATOMICS */
+/* #undef HAVE_GCC_SYNC_LOCK_TEST_AND_SET */
+/* #undef HAVE_PTHREAD_SPINLOCK */
+
+/* Comment this if you want to build without any C library requirements */
+#define HAVE_LIBC 1
+#if HAVE_LIBC
+
+/* Useful headers */
+#define HAVE_ALLOCA_H 1
+#define HAVE_SYS_TYPES_H 1
+#define HAVE_STDIO_H 1
+#define STDC_HEADERS 1
+#define HAVE_STDLIB_H 1
+#define HAVE_STDARG_H 1
+/* #undef HAVE_MALLOC_H */
+#define HAVE_MEMORY_H 1
+#define HAVE_STRING_H 1
+#define HAVE_STRINGS_H 1
+#define HAVE_INTTYPES_H 1
+#define HAVE_STDINT_H 1
+#define HAVE_CTYPE_H 1
+#define HAVE_MATH_H 1
+#define HAVE_ICONV_H 1
+#define HAVE_SIGNAL_H 1
+#define HAVE_ALTIVEC_H 1
+/* #undef HAVE_PTHREAD_NP_H */
+/* #undef HAVE_LIBUDEV_H */
+/* #undef HAVE_DBUS_DBUS_H */
 
-#ifdef USING_GENERATED_CONFIG_H
-#error Wrong SDL_config.h, check your include path?
+/* C library functions */
+#define HAVE_MALLOC 1
+#define HAVE_CALLOC 1
+#define HAVE_REALLOC 1
+#define HAVE_FREE 1
+#define HAVE_ALLOCA 1
+#ifndef __WIN32__ /* Don't use C runtime versions of these on Windows */
+#define HAVE_GETENV 1
+#define HAVE_SETENV 1
+#define HAVE_PUTENV 1
+#define HAVE_UNSETENV 1
 #endif
+#define HAVE_QSORT 1
+#define HAVE_ABS 1
+#define HAVE_BCOPY 1
+#define HAVE_MEMSET 1
+#define HAVE_MEMCPY 1
+#define HAVE_MEMMOVE 1
+#define HAVE_MEMCMP 1
+#define HAVE_STRLEN 1
+#define HAVE_STRLCPY 1
+#define HAVE_STRLCAT 1
+#define HAVE_STRDUP 1
+/* #undef HAVE__STRREV */
+/* #undef HAVE__STRUPR */
+/* #undef HAVE__STRLWR */
+/* #undef HAVE_INDEX */
+/* #undef HAVE_RINDEX */
+#define HAVE_STRCHR 1
+#define HAVE_STRRCHR 1
+#define HAVE_STRSTR 1
+/* #undef HAVE_ITOA */
+/* #undef HAVE__LTOA */
+/* #undef HAVE__UITOA */
+/* #undef HAVE__ULTOA */
+#define HAVE_STRTOL 1
+#define HAVE_STRTOUL 1
+/* #undef HAVE__I64TOA */
+/* #undef HAVE__UI64TOA */
+#define HAVE_STRTOLL 1
+#define HAVE_STRTOULL 1
+#define HAVE_STRTOD 1
+#define HAVE_ATOI 1
+#define HAVE_ATOF 1
+#define HAVE_STRCMP 1
+#define HAVE_STRNCMP 1
+/* #undef HAVE__STRICMP */
+#define HAVE_STRCASECMP 1
+/* #undef HAVE__STRNICMP */
+#define HAVE_STRNCASECMP 1
+/* #undef HAVE_SSCANF */
+#define HAVE_VSSCANF 1
+/* #undef HAVE_SNPRINTF */
+#define HAVE_VSNPRINTF 1
+#define HAVE_M_PI /**/
+#define HAVE_ATAN 1
+#define HAVE_ATAN2 1
+#define HAVE_ACOS 1
+#define HAVE_ASIN 1
+#define HAVE_CEIL 1
+#define HAVE_COPYSIGN 1
+#define HAVE_COS 1
+#define HAVE_COSF 1
+#define HAVE_FABS 1
+#define HAVE_FLOOR 1
+#define HAVE_LOG 1
+#define HAVE_POW 1
+#define HAVE_SCALBN 1
+#define HAVE_SIN 1
+#define HAVE_SINF 1
+#define HAVE_SQRT 1
+#define HAVE_FSEEKO 1
+/* #undef HAVE_FSEEKO64 */
+#define HAVE_SIGACTION 1
+#define HAVE_SA_SIGACTION 1
+#define HAVE_SETJMP 1
+#define HAVE_NANOSLEEP 1
+#define HAVE_SYSCONF 1
+#define HAVE_SYSCTLBYNAME 1
+/* #undef HAVE_CLOCK_GETTIME */
+/* #undef HAVE_GETPAGESIZE */
+#define HAVE_MPROTECT 1
+#define HAVE_ICONV 1
+/* #undef HAVE_PTHREAD_SETNAME_NP */
+/* #undef HAVE_PTHREAD_SET_NAME_NP */
+/* #undef HAVE_SEM_TIMEDWAIT */
+
+#else
+#define HAVE_STDARG_H 1
+#define HAVE_STDDEF_H 1
+#define HAVE_STDINT_H 1
+#endif /* HAVE_LIBC */
+
+/* SDL internal assertion support */
+/* #undef SDL_DEFAULT_ASSERT_LEVEL */
+
+/* Allow disabling of core subsystems */
+/* #undef SDL_ATOMIC_DISABLED */
+/* #undef SDL_AUDIO_DISABLED */
+/* #undef SDL_CPUINFO_DISABLED */
+/* #undef SDL_EVENTS_DISABLED */
+/* #undef SDL_FILE_DISABLED */
+/* #undef SDL_JOYSTICK_DISABLED */
+/* #undef SDL_HAPTIC_DISABLED */
+/* #undef SDL_LOADSO_DISABLED */
+/* #undef SDL_RENDER_DISABLED */
+/* #undef SDL_THREADS_DISABLED */
+/* #undef SDL_TIMERS_DISABLED */
+/* #undef SDL_VIDEO_DISABLED */
+/* #undef SDL_POWER_DISABLED */
+/* #undef SDL_FILESYSTEM_DISABLED */
+
+/* Enable various audio drivers */
+/* #undef SDL_AUDIO_DRIVER_ALSA */
+/* #undef SDL_AUDIO_DRIVER_ALSA_DYNAMIC */
+/* #undef SDL_AUDIO_DRIVER_ARTS */
+/* #undef SDL_AUDIO_DRIVER_ARTS_DYNAMIC */
+/* #undef SDL_AUDIO_DRIVER_PULSEAUDIO */
+/* #undef SDL_AUDIO_DRIVER_PULSEAUDIO_DYNAMIC */
+/* #undef SDL_AUDIO_DRIVER_HAIKU */
+/* #undef SDL_AUDIO_DRIVER_BSD */
+#define SDL_AUDIO_DRIVER_COREAUDIO 1
+#define SDL_AUDIO_DRIVER_DISK 1
+#define SDL_AUDIO_DRIVER_DUMMY 1
+/* #undef SDL_AUDIO_DRIVER_XAUDIO2 */
+/* #undef SDL_AUDIO_DRIVER_DSOUND */
+/* #undef SDL_AUDIO_DRIVER_ESD */
+/* #undef SDL_AUDIO_DRIVER_ESD_DYNAMIC */
+/* #undef SDL_AUDIO_DRIVER_NAS */
+/* #undef SDL_AUDIO_DRIVER_NAS_DYNAMIC */
+/* #undef SDL_AUDIO_DRIVER_SNDIO */
+/* #undef SDL_AUDIO_DRIVER_SNDIO_DYNAMIC */
+/* #undef SDL_AUDIO_DRIVER_OSS */
+/* #undef SDL_AUDIO_DRIVER_OSS_SOUNDCARD_H */
+/* #undef SDL_AUDIO_DRIVER_PAUDIO */
+/* #undef SDL_AUDIO_DRIVER_QSA */
+/* #undef SDL_AUDIO_DRIVER_SUNAUDIO */
+/* #undef SDL_AUDIO_DRIVER_WINMM */
+/* #undef SDL_AUDIO_DRIVER_FUSIONSOUND */
+/* #undef SDL_AUDIO_DRIVER_FUSIONSOUND_DYNAMIC */
+
+/* Enable various input drivers */
+/* #undef SDL_INPUT_LINUXEV */
+/* #undef SDL_INPUT_LINUXKD */
+/* #undef SDL_INPUT_TSLIB */
+/* #undef SDL_JOYSTICK_HAIKU */
+/* #undef SDL_JOYSTICK_DINPUT */
+/* #undef SDL_JOYSTICK_DUMMY */
+#define SDL_JOYSTICK_IOKIT 1
+/* #undef SDL_JOYSTICK_LINUX */
+/* #undef SDL_JOYSTICK_WINMM */
+/* #undef SDL_JOYSTICK_USBHID */
+/* #undef SDL_JOYSTICK_USBHID_MACHINE_JOYSTICK_H */
+/* #undef SDL_HAPTIC_DUMMY */
+/* #undef SDL_HAPTIC_LINUX */
+#define SDL_HAPTIC_IOKIT 1
+/* #undef SDL_HAPTIC_DINPUT */
+
+/* Enable various shared object loading systems */
+/* #undef SDL_LOADSO_HAIKU */
+#define SDL_LOADSO_DLOPEN 1
+/* #undef SDL_LOADSO_DUMMY */
+/* #undef SDL_LOADSO_LDG */
+/* #undef SDL_LOADSO_WINDOWS */
+
+/* Enable various threading systems */
+#define SDL_THREAD_PTHREAD 1
+#define SDL_THREAD_PTHREAD_RECURSIVE_MUTEX 1
+/* #undef SDL_THREAD_PTHREAD_RECURSIVE_MUTEX_NP */
+/* #undef SDL_THREAD_WINDOWS */
+
+/* Enable various timer systems */
+/* #undef SDL_TIMER_HAIKU */
+/* #undef SDL_TIMER_DUMMY */
+#define SDL_TIMER_UNIX 1
+/* #undef SDL_TIMER_WINDOWS */
+
+/* Enable various video drivers */
+/* #undef SDL_VIDEO_DRIVER_HAIKU */
+#define SDL_VIDEO_DRIVER_COCOA 1
+/* #undef SDL_VIDEO_DRIVER_DIRECTFB */
+/* #undef SDL_VIDEO_DRIVER_DIRECTFB_DYNAMIC */
+#define SDL_VIDEO_DRIVER_DUMMY 1
+/* #undef SDL_VIDEO_DRIVER_WINDOWS */
+/* #undef SDL_VIDEO_DRIVER_WAYLAND */
+/* #undef SDL_VIDEO_DRIVER_WAYLAND_QT_TOUCH */
+/* #undef SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC */
+/* #undef SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_EGL */
+/* #undef SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_CURSOR */
+/* #undef SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_XKBCOMMON */
+/* #undef SDL_VIDEO_DRIVER_MIR */
+/* #undef SDL_VIDEO_DRIVER_MIR_DYNAMIC */
+/* #undef SDL_VIDEO_DRIVER_MIR_DYNAMIC_XKBCOMMON */
+/* #undef SDL_VIDEO_DRIVER_X11 */
+/* #undef SDL_VIDEO_DRIVER_RPI */
+/* #undef SDL_VIDEO_DRIVER_X11_DYNAMIC */
+/* #undef SDL_VIDEO_DRIVER_X11_DYNAMIC_XEXT */
+/* #undef SDL_VIDEO_DRIVER_X11_DYNAMIC_XCURSOR */
+/* #undef SDL_VIDEO_DRIVER_X11_DYNAMIC_XINERAMA */
+/* #undef SDL_VIDEO_DRIVER_X11_DYNAMIC_XINPUT2 */
+/* #undef SDL_VIDEO_DRIVER_X11_DYNAMIC_XRANDR */
+/* #undef SDL_VIDEO_DRIVER_X11_DYNAMIC_XSS */
+/* #undef SDL_VIDEO_DRIVER_X11_DYNAMIC_XVIDMODE */
+/* #undef SDL_VIDEO_DRIVER_X11_XCURSOR */
+/* #undef SDL_VIDEO_DRIVER_X11_XINERAMA */
+/* #undef SDL_VIDEO_DRIVER_X11_XINPUT2 */
+/* #undef SDL_VIDEO_DRIVER_X11_XINPUT2_SUPPORTS_MULTITOUCH */
+/* #undef SDL_VIDEO_DRIVER_X11_XRANDR */
+/* #undef SDL_VIDEO_DRIVER_X11_XSCRNSAVER */
+/* #undef SDL_VIDEO_DRIVER_X11_XSHAPE */
+/* #undef SDL_VIDEO_DRIVER_X11_XVIDMODE */
+/* #undef SDL_VIDEO_DRIVER_X11_SUPPORTS_GENERIC_EVENTS */
+/* #undef SDL_VIDEO_DRIVER_X11_CONST_PARAM_XDATA32 */
+/* #undef SDL_VIDEO_DRIVER_X11_CONST_PARAM_XEXTADDDISPLAY */
+/* #undef SDL_VIDEO_DRIVER_X11_HAS_XKBKEYCODETOKEYSYM */
+
+/* #undef SDL_VIDEO_RENDER_D3D */
+/* #undef SDL_VIDEO_RENDER_D3D11 */
+#define SDL_VIDEO_RENDER_OGL 1
+/* #undef SDL_VIDEO_RENDER_OGL_ES */
+/* #undef SDL_VIDEO_RENDER_OGL_ES2 */
+/* #undef SDL_VIDEO_RENDER_DIRECTFB */
+
+/* Enable OpenGL support */
+#define SDL_VIDEO_OPENGL 1
+/* #undef SDL_VIDEO_OPENGL_ES */
+/* #undef SDL_VIDEO_OPENGL_ES2 */
+/* #undef SDL_VIDEO_OPENGL_BGL */
+#define SDL_VIDEO_OPENGL_CGL 1
+/* #undef SDL_VIDEO_OPENGL_EGL */
+/* #undef SDL_VIDEO_OPENGL_GLX */
+/* #undef SDL_VIDEO_OPENGL_WGL */
+/* #undef SDL_VIDEO_OPENGL_OSMESA */
+/* #undef SDL_VIDEO_OPENGL_OSMESA_DYNAMIC */
+
+/* Enable system power support */
+/* #undef SDL_POWER_LINUX */
+/* #undef SDL_POWER_WINDOWS */
+#define SDL_POWER_MACOSX 1
+/* #undef SDL_POWER_HAIKU */
+/* #undef SDL_POWER_HARDWIRED */
+
+/* Enable system filesystem support */
+/* #undef SDL_FILESYSTEM_HAIKU */
+#define SDL_FILESYSTEM_COCOA 1
+/* #undef SDL_FILESYSTEM_DUMMY */
+/* #undef SDL_FILESYSTEM_UNIX */
+/* #undef SDL_FILESYSTEM_WINDOWS */
+
+/* Enable assembly routines */
+#define SDL_ASSEMBLY_ROUTINES 1
+#define SDL_ALTIVEC_BLITTERS 1
 
 #endif /* _SDL_config_h */
diff -ru SDL2-2.0.3-orig/include/SDL_platform.h SDL2-2.0.3/include/SDL_platform.h
--- SDL2-2.0.3-orig/include/SDL_platform.h	2014-03-16 03:31:42.000000000 +0100
+++ SDL2-2.0.3/include/SDL_platform.h	2015-10-28 16:35:36.000000000 +0100
@@ -70,7 +70,7 @@
 /* lets us know what version of Mac OS X we're compiling on */
 #include "AvailabilityMacros.h"
 #include "TargetConditionals.h"
-#if TARGET_OS_IPHONE
+#if defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE
 /* if compiling for iPhone */
 #undef __IPHONEOS__
 #define __IPHONEOS__ 1
@@ -80,7 +80,9 @@
 #undef __MACOSX__
 #define __MACOSX__  1
 #if MAC_OS_X_VERSION_MIN_REQUIRED < 1050
+#if 0
 # error SDL for Mac OS X only supports deploying on 10.5 and above.
+#endif
 #endif /* MAC_OS_X_VERSION_MIN_REQUIRED < 1050 */
 #endif /* TARGET_OS_IPHONE */
 #endif /* defined(__APPLE__) */
Only in SDL2-2.0.3: libtool
Only in SDL2-2.0.3: sdl2-config
Only in SDL2-2.0.3: sdl2.pc
diff -ru SDL2-2.0.3-orig/src/joystick/darwin/SDL_sysjoystick.c SDL2-2.0.3/src/joystick/darwin/SDL_sysjoystick.c
--- SDL2-2.0.3-orig/src/joystick/darwin/SDL_sysjoystick.c	2014-03-16 03:31:41.000000000 +0100
+++ SDL2-2.0.3/src/joystick/darwin/SDL_sysjoystick.c	2015-10-28 16:03:29.000000000 +0100
@@ -384,6 +384,7 @@
     device->instance_id = ++s_joystick_instance_id;
 
     /* We have to do some storage of the io_service_t for SDL_HapticOpenFromJoystick */
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
     if (IOHIDDeviceGetService != NULL) {  /* weak reference: available in 10.6 and later. */
         const io_service_t ioservice = IOHIDDeviceGetService(ioHIDDeviceObject);
         if ((ioservice) && (FFIsForceFeedback(ioservice) == FF_OK)) {
@@ -393,6 +394,7 @@
 #endif
         }
     }
+#endif
 
     device->send_open_event = 1;
     s_bDeviceAdded = SDL_TRUE;
diff -ru SDL2-2.0.3-orig/src/video/cocoa/SDL_cocoaclipboard.m SDL2-2.0.3/src/video/cocoa/SDL_cocoaclipboard.m
--- SDL2-2.0.3-orig/src/video/cocoa/SDL_cocoaclipboard.m	2014-03-16 03:31:45.000000000 +0100
+++ SDL2-2.0.3/src/video/cocoa/SDL_cocoaclipboard.m	2015-10-28 15:15:13.000000000 +0100
@@ -30,11 +30,15 @@
 {
     SDL_VideoData *data = (SDL_VideoData *) _this->driverdata;
 
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
     if (data->osversion >= 0x1060) {
         return NSPasteboardTypeString;
     } else {
+#endif
         return NSStringPboardType;
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
     }
+#endif
 }
 
 int
diff -ru SDL2-2.0.3-orig/src/video/cocoa/SDL_cocoamodes.m SDL2-2.0.3/src/video/cocoa/SDL_cocoamodes.m
--- SDL2-2.0.3-orig/src/video/cocoa/SDL_cocoamodes.m	2014-03-16 03:31:41.000000000 +0100
+++ SDL2-2.0.3/src/video/cocoa/SDL_cocoamodes.m	2015-10-28 15:27:02.000000000 +0100
@@ -127,6 +127,7 @@
     }
     data->moderef = moderef;
 
+    #if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
     if (IS_SNOW_LEOPARD_OR_LATER(_this)) {
         CGDisplayModeRef vidmode = (CGDisplayModeRef) moderef;
         CFStringRef fmt = CGDisplayModeCopyPixelEncoding(vidmode);
@@ -146,6 +147,7 @@
 
         CFRelease(fmt);
     }
+    #endif
 
     #if MAC_OS_X_VERSION_MIN_REQUIRED < 1060
     if (!IS_SNOW_LEOPARD_OR_LATER(_this)) {
@@ -184,17 +186,21 @@
 static void
 Cocoa_ReleaseDisplayMode(_THIS, const void *moderef)
 {
+    #if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
     if (IS_SNOW_LEOPARD_OR_LATER(_this)) {
         CGDisplayModeRelease((CGDisplayModeRef) moderef);  /* NULL is ok */
     }
+    #endif
 }
 
 static void
 Cocoa_ReleaseDisplayModeList(_THIS, CFArrayRef modelist)
 {
+    #if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
     if (IS_SNOW_LEOPARD_OR_LATER(_this)) {
         CFRelease(modelist);  /* NULL is ok */
     }
+    #endif
 }
 
 static const char *
@@ -257,9 +263,11 @@
                 continue;
             }
 
+            #if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
             if (IS_SNOW_LEOPARD_OR_LATER(_this)) {
                 moderef = CGDisplayCopyDisplayMode(displays[i]);
             }
+            #endif
 
             #if MAC_OS_X_VERSION_MIN_REQUIRED < 1060
             if (!IS_SNOW_LEOPARD_OR_LATER(_this)) {
@@ -319,9 +327,11 @@
     SDL_DisplayData *data = (SDL_DisplayData *) display->driverdata;
     CFArrayRef modes = NULL;
 
+    #if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
     if (IS_SNOW_LEOPARD_OR_LATER(_this)) {
         modes = CGDisplayCopyAllDisplayModes(data->display, NULL);
     }
+    #endif
 
     #if MAC_OS_X_VERSION_MIN_REQUIRED < 1060
     if (!IS_SNOW_LEOPARD_OR_LATER(_this)) {
@@ -337,9 +347,11 @@
             const void *moderef = CFArrayGetValueAtIndex(modes, i);
             SDL_DisplayMode mode;
             if (GetDisplayMode(_this, moderef, &mode)) {
+    #if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
                 if (IS_SNOW_LEOPARD_OR_LATER(_this)) {
                     CGDisplayModeRetain((CGDisplayModeRef) moderef);
                 }
+    #endif
                 SDL_AddDisplayMode(display, &mode);
             }
         }
@@ -351,9 +363,11 @@
 static CGError
 Cocoa_SwitchMode(_THIS, CGDirectDisplayID display, const void *mode)
 {
+    #if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
     if (IS_SNOW_LEOPARD_OR_LATER(_this)) {
         return CGDisplaySetDisplayMode(display, (CGDisplayModeRef) mode, NULL);
     }
+    #endif
  
     #if MAC_OS_X_VERSION_MIN_REQUIRED < 1060
     if (!IS_SNOW_LEOPARD_OR_LATER(_this)) {
diff -ru SDL2-2.0.3-orig/src/video/cocoa/SDL_cocoaopengl.m SDL2-2.0.3/src/video/cocoa/SDL_cocoaopengl.m
--- SDL2-2.0.3-orig/src/video/cocoa/SDL_cocoaopengl.m	2014-03-16 03:31:41.000000000 +0100
+++ SDL2-2.0.3/src/video/cocoa/SDL_cocoaopengl.m	2015-10-28 15:32:58.000000000 +0100
@@ -347,9 +347,11 @@
 
     /* This gives us the correct viewport for a Retina-enabled view, only
      * supported on 10.7+. */
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1070
     if ([contentView respondsToSelector:@selector(convertRectToBacking:)]) {
         viewport = [contentView convertRectToBacking:viewport];
     }
+#endif
 
     if (w) {
         *w = viewport.size.width;
diff -ru SDL2-2.0.3-orig/src/video/cocoa/SDL_cocoawindow.h SDL2-2.0.3/src/video/cocoa/SDL_cocoawindow.h
--- SDL2-2.0.3-orig/src/video/cocoa/SDL_cocoawindow.h	2014-03-16 03:31:41.000000000 +0100
+++ SDL2-2.0.3/src/video/cocoa/SDL_cocoawindow.h	2015-10-28 15:11:29.000000000 +0100
@@ -35,7 +35,11 @@
     PENDING_OPERATION_MINIMIZE
 } PendingWindowOperation;
 
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
 @interface Cocoa_WindowListener : NSResponder <NSWindowDelegate> {
+#else
+@interface Cocoa_WindowListener : NSResponder {
+#endif
     SDL_WindowData *_data;
     BOOL observingVisible;
     BOOL wasCtrlLeft;
@@ -73,7 +77,9 @@
 -(void) windowDidEnterFullScreen:(NSNotification *) aNotification;
 -(void) windowWillExitFullScreen:(NSNotification *) aNotification;
 -(void) windowDidExitFullScreen:(NSNotification *) aNotification;
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1070
 -(NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions;
+#endif
 
 /* Window event handling */
 -(void) mouseDown:(NSEvent *) theEvent;
diff -ru SDL2-2.0.3-orig/src/video/cocoa/SDL_cocoawindow.m SDL2-2.0.3/src/video/cocoa/SDL_cocoawindow.m
--- SDL2-2.0.3-orig/src/video/cocoa/SDL_cocoawindow.m	2014-03-16 03:31:41.000000000 +0100
+++ SDL2-2.0.3/src/video/cocoa/SDL_cocoawindow.m	2015-10-28 15:55:03.000000000 +0100
@@ -23,7 +23,9 @@
 #if SDL_VIDEO_DRIVER_COCOA
 
 #if MAC_OS_X_VERSION_MAX_ALLOWED < 1070
+#if 0
 # error SDL for Mac OS X must be built with a 10.7 SDK or above.
+#endif
 #endif /* MAC_OS_X_VERSION_MAX_ALLOWED < 1070 */
 
 #include "SDL_syswm.h"
@@ -190,10 +192,12 @@
         [center addObserver:self selector:@selector(windowDidDeminiaturize:) name:NSWindowDidDeminiaturizeNotification object:window];
         [center addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:window];
         [center addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:window];
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1070
         [center addObserver:self selector:@selector(windowWillEnterFullScreen:) name:NSWindowWillEnterFullScreenNotification object:window];
         [center addObserver:self selector:@selector(windowDidEnterFullScreen:) name:NSWindowDidEnterFullScreenNotification object:window];
         [center addObserver:self selector:@selector(windowWillExitFullScreen:) name:NSWindowWillExitFullScreenNotification object:window];
         [center addObserver:self selector:@selector(windowDidExitFullScreen:) name:NSWindowDidExitFullScreenNotification object:window];
+#endif
     } else {
         [window setDelegate:self];
     }
@@ -212,9 +216,11 @@
 
     [view setNextResponder:self];
 
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
     if ([view respondsToSelector:@selector(setAcceptsTouchEvents:)]) {
         [view setAcceptsTouchEvents:YES];
     }
+#endif
 }
 
 - (void)observeValueForKeyPath:(NSString *)keyPath
@@ -282,7 +288,9 @@
     inFullscreenTransition = YES;
 
     /* you need to be FullScreenPrimary, or toggleFullScreen doesn't work. Unset it again in windowDidExitFullScreen. */
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1070
     [nswindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
+#endif
     [nswindow performSelectorOnMainThread: @selector(toggleFullScreen:) withObject:nswindow waitUntilDone:NO];
     return YES;
 }
@@ -319,10 +327,12 @@
         [center removeObserver:self name:NSWindowDidDeminiaturizeNotification object:window];
         [center removeObserver:self name:NSWindowDidBecomeKeyNotification object:window];
         [center removeObserver:self name:NSWindowDidResignKeyNotification object:window];
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1070
         [center removeObserver:self name:NSWindowWillEnterFullScreenNotification object:window];
         [center removeObserver:self name:NSWindowDidEnterFullScreenNotification object:window];
         [center removeObserver:self name:NSWindowWillExitFullScreenNotification object:window];
         [center removeObserver:self name:NSWindowDidExitFullScreenNotification object:window];
+#endif
     } else {
         [window setDelegate:nil];
     }
@@ -597,12 +607,14 @@
         [nswindow miniaturize:nil];
     } else {
         /* Adjust the fullscreen toggle button and readd menu now that we're here. */
+#if MAC_OS_X_VERSION_MIN_REQUIRED > 1070
         if (window->flags & SDL_WINDOW_RESIZABLE) {
             /* resizable windows are Spaces-friendly: they get the "go fullscreen" toggle button on their titlebar. */
             [nswindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
         } else {
             [nswindow setCollectionBehavior:NSWindowCollectionBehaviorManaged];
         }
+#endif
         [NSMenu setMenuBarVisible:YES];
 
         pendingWindowOperation = PENDING_OPERATION_NONE;
@@ -620,6 +632,7 @@
     }
 }
 
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1070
 -(NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions
 {
     if ((_data->window->flags & SDL_WINDOW_FULLSCREEN_DESKTOP) == SDL_WINDOW_FULLSCREEN_DESKTOP) {
@@ -628,6 +641,7 @@
         return proposedOptions;
     }
 }
+#endif
 
 
 /* We'll respond to key events by doing nothing so we don't beep.
@@ -822,6 +836,7 @@
     [self handleTouches:COCOA_TOUCH_CANCELLED withEvent:theEvent];
 }
 
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
 - (void)handleTouches:(cocoaTouchType)type withEvent:(NSEvent *)event
 {
     NSSet *touches = 0;
@@ -875,6 +890,7 @@
         touch = (NSTouch*)[enumerator nextObject];
     }
 }
+#endif
 
 @end
 
@@ -1040,6 +1056,7 @@
     [nswindow setBackgroundColor:[NSColor blackColor]];
 
     if (videodata->allow_spaces) {
+#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1070
         SDL_assert(videodata->osversion >= 0x1070);
         SDL_assert([nswindow respondsToSelector:@selector(toggleFullScreen:)]);
         /* we put FULLSCREEN_DESKTOP windows in their own Space, without a toggle button or menubar, later */
@@ -1047,6 +1064,7 @@
             /* resizable windows are Spaces-friendly: they get the "go fullscreen" toggle button on their titlebar. */
             [nswindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
         }
+#endif
     }
 
     /* Create a default view for this window */
PATCH_EOF

CFLAGS="$(leopard.sh -mcpu -O) $CFLAGS"
CXXFLAGS="$(leopard.sh -mcpu -O) $CXXFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    CXXFLAGS="-m64 $CXXFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time ./configure -C --prefix=/opt/$pkgspec \
    --disable-dependency-tracking \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS"

/usr/bin/time make $(leopard.sh -j) V=1

if test -n "$LEOPARDSH_RUN_TESTS" ; then
    make check
fi

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
