#!/bin/bash

set -E

mount /dev/sda2 /mnt

rsync -av                                 \
      --mkpath                            \
      /mnt/home/rod/.cache/pikaur/pkg/    \
      rod@$IP:/eden/forge/applet/os/laceOS/applet/lace-live/profile/airootfs/root/packages/aur
      
sync
umount -R /mnt

echo Done.