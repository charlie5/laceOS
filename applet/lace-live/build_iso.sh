#!/bin/bash

set -e

cp ../installer/install_laceOS  \
   profile/airootfs/usr/local/bin
   
sudo mkarchiso -v                        \
               -A "laceOS Installer"     \
               -L "laceOS_ISO"           \
               -P "Rod Kay"              \
               -w /tmp/archiso-tmp       \
               profile

echo Done.