#!/bin/bash

set -e

#pushd ../installer
#gprbuild -P laceos_installer
#popd

cp ../installer/install_laceOS  \
   profile/airootfs/usr/local/bin
   
sudo mkarchiso -v -w /tmp/archiso-tmp profile

echo Done.