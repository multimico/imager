#!/bin/bash

# The default cloud init repo to use


if [ -z $GIT_SERVER ]
then 
  GIT_SERVER=https://raw.githubusercontent.com
fi

if [ -z $GIT_REPO ]
then 
  GIT_REPO=multimico/init
fi 

if [ -z $GIT_BRANCH ]
then 
  GIT_BRANCH=cloud-init
fi

if [ -z $RELEASE ]
then 
  RELEASE=22.04
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
  echo "⚠️ You may want or need to delete the old image in order to get the latest updates!"
  exit 0
fi

wget https://releases.ubuntu.com/$RELEASE/$ISO

if [ ! -f $ISO ]
then
  echo "No ISO Downloaded 💩"
  exit 1
fi 

# Extract the MBR template
# ubuntu 21.10 uses 446
# ubuntu 22.04 uses 432
# 512 should be correct as it is the first sector
# The  bootloader complains but fixes itself (at least for 21.10 and 22.04)
dd if="$ISO" bs=1 count=512 of="$MBR"

# Extract EFI partition image
SKIP=$(/sbin/fdisk -l "$ISO" | fgrep '.iso2 ' | awk '{print $2}')
SIZE=$(/sbin/fdisk -l "$ISO" | fgrep '.iso2 ' | awk '{print $4}')
dd if="$ISO" bs=512 skip="$SKIP" count="$SIZE" of="$EFI"

xorriso -osirrox on -indev "$ISO" -extract / iso_helper && chmod -R +w iso_helper

# Inject the autoinstall cloud-init hook to grub
sed -i "s|---|ip=dhcp autoinstall \"ds=nocloud-net;s=${GIT_SERVER}/${GIT_REPO}/${GIT_BRANCH}/\" ---|g" iso_helper/boot/grub/grub.cfg

# drop the timeout to 0 secs since we will boot headless
sed -i "s|set timeout=30|set timeout=0|g" iso_helper/boot/grub/grub.cfg

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