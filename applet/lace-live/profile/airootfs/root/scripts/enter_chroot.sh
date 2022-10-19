#!/bin/bash

set -e

#umount -R /mnt
mount /dev/vda2 /mnt
mount /dev/vda1 /mnt/boot

chmod a+rwx /root/scripts/build_aur_packages.sh
cp /root/scripts/build_aur_packages.sh /mnt/home/rod

arch-chroot /mnt  su - rod

#su - rod
#sudo chown rod ./build_aur_packages.sh

#exit
#umount -R /mnt


echo Done.