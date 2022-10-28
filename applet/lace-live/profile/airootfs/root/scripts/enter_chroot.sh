#!/bin/bash

set -e

mount /dev/sda2 /mnt
mount /dev/sda1 /mnt/boot

chmod a+rwx /root/scripts/build_aur_packages.sh
cp /root/scripts/build_aur_packages.sh /mnt/home/rod

arch-chroot /mnt  su - rod

echo Done.