#!/bin/bash

set -E

mount /dev/sda2 /mnt

rsync -av                          \
      --mkpath                     \
      /mnt/var/cache/pacman/pkg/   \
      rod@$IP:/eden/forge/applet/os/laceOS/applet/lace-live/profile/airootfs/root/custom/var/cache/pacman/pkg
      
sync
umount -R /mnt

echo Done.