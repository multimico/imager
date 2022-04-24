#!/bin/bash

if [ -z $RELEASE ]
then 
  RELEASE=21.10
fi

if [ -z $EXTENSION ]
then 
  EXTENSION=multimico
fi 

ISO="ubuntu-$RELEASE-live-server-amd64.iso"

OUTPUTISO=$(echo $ISO | sed -E "s/.iso/-$EXTENSION.iso/")
MBR=$(echo $ISO | sed -E "s/.iso/.mbr/")
EFI=$(echo $ISO | sed -E "s/.iso/.efi/")

mkdir -p /run/isobuild
cd /run/isobuild

if [ -f /data/$OUTPUTISO ]
then
  echo "Custom ISO already exists 👍"
  echo "⚠️ You may want or need to delete the old image to get the latest updates!"
  exit 0
fi

wget https://releases.ubuntu.com/$RELEASE/$ISO

if [ ! -f $ISO ]
then
  echo "No ISO Downloaded 😢"
  exit 1
fi 

# Extract the MBR template
dd if="$ISO" bs=1 count=446 of="$MBR"

# Extract EFI partition image
SKIP=$(/sbin/fdisk -l "$ISO" | fgrep '.iso2 ' | awk '{print $2}')
SIZE=$(/sbin/fdisk -l "$ISO" | fgrep '.iso2 ' | awk '{print $4}')
dd if="$ISO" bs=512 skip="$SKIP" count="$SIZE" of="$EFI"

xorriso -osirrox on -indev "$ISO" -extract / iso_helper && chmod -R +w iso_helper

# Inject our autoinstall user data hook
sed -i 's|---|ip=dhcp autoinstall "ds=nocloud-net;s=https://raw.githubusercontent.com/multimico/init/cloud-init/" ---|g' iso_helper/boot/grub/grub.cfg

# Integritätscheck noch auffrischen. 
mv iso_helper/ubuntu .

(cd iso_helper; find '!' -name "md5sum.txt" '!' -path "./isolinux/*" -follow -type f -exec "$(which md5sum)" {} \; > ../md5sum.txt)

mv md5sum.txt ubuntu iso_helper/

# ISO neu bauen

xorriso -as mkisofs \
  -r -V "Ubuntu $RELEASE Autoinstaller" -J -joliet-long -l \
  -iso-level 3 \
  -partition_offset 16 \
  --grub2-mbr "$MBR" \
  --mbr-force-bootable \
  -append_partition 2 0xEF "$EFI" \
  -appended_part_as_gpt \
  -c /boot.catalog \
  -b /boot/grub/i386-pc/eltorito.img \
    -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  -eltorito-alt-boot \
  -e '--interval:appended_partition_2:all::' \
    -no-emul-boot \
  -o "$OUTPUTISO" \
  iso_helper

echo -n "Start copying the new ISO image ☕️ ... "

cp $OUTPUTISO /data/$OUTPUTISO

echo "✅ 🥳"