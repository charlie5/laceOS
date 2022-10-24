#!/bin/bash

set -E

#export IP=192.168.165.253
#export IP=192.168.33.67

mount /dev/sda2 /mnt

rsync -av                                 \
      --mkpath                            \
      /mnt/home/rod/.cache/pikaur/pkg/    \
      rod@$IP:/eden/forge/applet/os/laceOS/applet/lace-live/profile/airootfs/root/aur
      
umount /mnt

echo Done.