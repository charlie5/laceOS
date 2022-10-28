#!/bin/bash

set -e

export LACE_LIVE='/eden/forge/applet/os/laceOS/applet/lace-live'
cd    $LACE_LIVE


echo
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~
echo Building builder_packages.
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~
echo

sleep 2
pikaur -Syu
rm -fr ~/.cache/pikaur/*
pikaur -S --noconfirm pikaur
pikaur -S --noconfirm xmlada libgpr gprbuild
rsync -av ~/.cache/pikaur/pkg/ profile/airootfs/root/packages/builder


echo
echo ~~~~~~~~~~~~~~~~~~~~~~~
echo Rid ISO package caches.
echo ~~~~~~~~~~~~~~~~~~~~~~~
echo

sleep 2
./rid_iso_package_caches.sh
./rid_iso.sh


echo
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~
echo Build and export the ISO.
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~
echo

sleep 2
./build_iso.sh
./export_iso.sh


echo Prepare done.