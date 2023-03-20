#!/bin/bash

# Add pv, lzop and socat to finnix-ppc-111.iso.

set -e -o pipefail
set -x

if test "$(whoami)" != "root" ; then
    echo "Error: must be run as root" >&2
    exit 1
fi

if ! which xorriso \
|| ! which unsquashfs \
|| ! which mksquashfs \
|| ! which genisoimage \
; then
    echo "Error: some dependencies are missing." >&2
    echo "Please apt-get install xorriso squashfs-tools genisoimage" >&2
    exit 1
fi

cd /tmp

if ! test -e finnix-ppc-111.iso ; then
    wget https://ftp.osuosl.org/pub/finnix/111/finnix-ppc-111.iso
fi

rm -rf iso
mkdir iso

# extract the iso image
xorriso -osirrox on -indev finnix-ppc-111.iso -extract / ./iso

# extract the squashfs filesystem
rm -rf squash
unsquashfs -d squash iso/finnix/arch/ppc/root.img

# copy some additional files into the filesystem
for f in lzop socat pv ; do
    if ! test -e $f ; then
        wget https://leopard.sh/linux/$f
        chmod +x $f
    fi
    cp $f squash/usr/local/bin/
done

# re-squash
rm -f root.img
mksquashfs squash root.img -comp xz -Xbcj powerpc
mv root.img iso/finnix/arch/ppc/

# re-iso
rm -f finnix-ppc-111b.iso
genisoimage -hide-rr-moved -hfs -part \
    -map iso/boot/ppc/hfs.map \
    -no-desktop \
    -hfs-volid finnix_111b \
    -hfs-bless iso/boot/ppc \
    -pad -l -r -J -v -V "Finnix 111b" \
    -o finnix-ppc-111b.iso \
    iso
