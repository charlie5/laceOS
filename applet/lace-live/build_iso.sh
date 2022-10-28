#!/bin/bash

set -e

cp ../installer/install_laceOS  \
   profile/airootfs/usr/local/bin
   
sudo mkarchiso -v -w /tmp/archiso-tmp profile

echo Done.