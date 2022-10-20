#!/bin/bash

set -e

export LACE_LIVE='/eden/forge/applet/os/laceOS/applet/lace-live'

cd $LACE_LIVE

pikaur -Syu
rm -fr ~/.cache/pikaur/*
pikaur -S --noconfirm pikaur
pikaur -S --noconfirm xmlada libgpr gprbuild
rsync -av ~/.cache/pikaur/pkg/ profile/airootfs/root/builder_packages

./rid_iso_package_caches.sh
./rid_iso.sh
./build_iso.sh
./export_iso.sh


echo Prepare done.