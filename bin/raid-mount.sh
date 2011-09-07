#!/bin/sh

umount /media/home
cryptsetup remove home

# Incase the devices has changed dev name ie. /dev/sdb to /dev/sdg
mdadm -S /dev/md0
mdadm --assemble --force --scan /dev/md0

mdadm  --detail /dev/md0
cryptsetup -c twofish-cbc-essiv:sha256 create home /dev/md0
mount -t ext3 -O noatime /dev/mapper/home /media/home
ls /media/home
