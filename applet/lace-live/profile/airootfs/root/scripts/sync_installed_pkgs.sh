#!/bin/bash

set -E

#export IP=192.168.165.253
#export IP=192.168.33.67

mount /dev/vda2 /mnt

rsync -av                          \
      --mkpath                     \
      --delete                     \
      /mnt/var/cache/pacman/pkg/   \
      rod@$IP:/eden/forge/applet/os/laceOS/applet/lace-live/profile/airootfs/root/custom/var/cache/pacman/pkg
      
umount /mnt

echo Done.