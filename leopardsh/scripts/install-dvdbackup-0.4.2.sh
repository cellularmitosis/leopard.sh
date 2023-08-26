#!/bin/bash
# based on templates/build-from-source.sh v6

# Install dvdbackup on OS X Leopard / PowerPC.

package=dvdbackup
version=0.4.2
upstream=http://downloads.sourceforge.net/dvdbackup/dvdbackup-$version.tar.gz
description="Backup content from DVD to hard disk"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

dep=libdvdread-6.1.3$ppc64
if ! test -e /opt/$dep ; then
    leopard.sh $dep
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

if ! which -s gcc-4.2 ; then
    leopard.sh gcc-4.2
fi
CC=gcc-4.2

echo -n -e "\033]0;leopard.sh $pkgspec ($(leopard.sh --cpu))\007"

leopard.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

# Thanks to https://launchpadlibrarian.net/580446167/newlibdvdread.patch
patch -p1 << 'EOF'
diff --git a/src/dvdbackup.c b/src/dvdbackup.c
index 5888ce5..fae109d 100644
--- a/src/dvdbackup.c
+++ b/src/dvdbackup.c
@@ -1132,7 +1132,7 @@ static int DVDCopyIfoBup(dvd_reader_t* dvd, title_set_info_t* title_set_info, in
 	int size;
 
 	/* DVD handler */
-	ifo_handle_t* ifo_file = NULL;
+    dvd_file_t* ifo_file = NULL;
 
 
 	if (title_set_info->number_of_title_sets + 1 < title_set) {
@@ -1181,7 +1181,7 @@ static int DVDCopyIfoBup(dvd_reader_t* dvd, title_set_info_t* title_set_info, in
 	if ((streamout_ifo = open(targetname_ifo, O_WRONLY | O_CREAT | O_TRUNC, 0666)) == -1) {
 		fprintf(stderr, _("Error creating %s\n"), targetname_ifo);
 		perror(PACKAGE);
-		ifoClose(ifo_file);
+        DVDCloseFile(ifo_file);
 		free(buffer);
 		close(streamout_ifo);
 		close(streamout_bup);
@@ -1191,7 +1191,7 @@ static int DVDCopyIfoBup(dvd_reader_t* dvd, title_set_info_t* title_set_info, in
 	if ((streamout_bup = open(targetname_bup, O_WRONLY | O_CREAT | O_TRUNC, 0666)) == -1) {
 		fprintf(stderr, _("Error creating %s\n"), targetname_bup);
 		perror(PACKAGE);
-		ifoClose(ifo_file);
+        DVDCloseFile(ifo_file);
 		free(buffer);
 		close(streamout_ifo);
 		close(streamout_bup);
@@ -1200,31 +1200,31 @@ static int DVDCopyIfoBup(dvd_reader_t* dvd, title_set_info_t* title_set_info, in
 
 	/* Copy VIDEO_TS.IFO, since it's a small file try to copy it in one shot */
 
-	if ((ifo_file = ifoOpen(dvd, title_set))== 0) {
+    if ((ifo_file = DVDOpenFile(dvd, title_set, DVD_READ_INFO_FILE))== 0) {
 		fprintf(stderr, _("Failed opening IFO for title set %d\n"), title_set);
-		ifoClose(ifo_file);
+        DVDCloseFile(ifo_file);
 		free(buffer);
 		close(streamout_ifo);
 		close(streamout_bup);
 		return 1;
 	}
 
-	size = DVDFileSize(ifo_file->file) * DVD_VIDEO_LB_LEN;
+    size = DVDFileSize(ifo_file) * DVD_VIDEO_LB_LEN;
 
 	if ((buffer = (unsigned char *)malloc(size * sizeof(unsigned char))) == NULL) {
 		perror(PACKAGE);
-		ifoClose(ifo_file);
+        DVDCloseFile(ifo_file);
 		free(buffer);
 		close(streamout_ifo);
 		close(streamout_bup);
 		return 1;
 	}
 
-	DVDFileSeek(ifo_file->file, 0);
+    DVDFileSeek(ifo_file, 0);
 
-	if (DVDReadBytes(ifo_file->file,buffer,size) != size) {
+    if (DVDReadBytes(ifo_file,buffer,size) != size) {
 		fprintf(stderr, _("Error reading IFO for title set %d\n"), title_set);
-		ifoClose(ifo_file);
+        DVDCloseFile(ifo_file);
 		free(buffer);
 		close(streamout_ifo);
 		close(streamout_bup);
@@ -1234,7 +1234,7 @@ static int DVDCopyIfoBup(dvd_reader_t* dvd, title_set_info_t* title_set_info, in
 
 	if (write(streamout_ifo,buffer,size) != size) {
 		fprintf(stderr, _("Error writing %s\n"),targetname_ifo);
-		ifoClose(ifo_file);
+        DVDCloseFile(ifo_file);
 		free(buffer);
 		close(streamout_ifo);
 		close(streamout_bup);
@@ -1243,7 +1243,7 @@ static int DVDCopyIfoBup(dvd_reader_t* dvd, title_set_info_t* title_set_info, in
 
 	if (write(streamout_bup,buffer,size) != size) {
 		fprintf(stderr, _("Error writing %s\n"),targetname_bup);
-		ifoClose(ifo_file);
+        DVDCloseFile(ifo_file);
 		free(buffer);
 		close(streamout_ifo);
 		close(streamout_bup);
EOF

CFLAGS="$(leopard.sh -mcpu -O) $CFLAGS"
if test -n "$ppc64" ; then
    CFLAGS="-m64 $CFLAGS"
    LDFLAGS="-m64 $LDFLAGS"
fi

/usr/bin/time env \
    CC=gcc-4.2 \
    CFLAGS='-I/opt/libdvdread-6.1.3/include' \
    LDFLAGS='-L/opt/libdvdread-6.1.3/lib' \
    LIBS='-ldvdread' \
    ./configure -C --prefix=/opt/$pkgspec \
        --disable-dependency-tracking \
        --disable-maintainer-mode \
        --disable-debug

/usr/bin/time make $(leopard.sh -j) V=1

# Note: no 'make check' available.

make install

leopard.sh --linker-check $pkgspec
leopard.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/
fi
