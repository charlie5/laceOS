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
rm -fr /tmp/makepkg/*
pikaur -S --noconfirm pikaur

set +e
pikaur -Rsc --confirm xmlada
pikaur -Rsc --confirm gprbuild-toolbox
pikaur -Rsc --confirm gprbuild-bootstrap
set -e

#pikaur -S --noconfirm gprbuild-toolbox    #xmlada libgpr gprbuild
pikaur -S gprbuild-bootstrap
pikaur -S gprbuild gprtools libgpr
pikaur -S gprbuild-toolbox

rm                 ~/.cache/pikaur/pkg/gprbuild-bootstrap-*.zst
rsync -av --delete ~/.cache/pikaur/pkg/ profile/airootfs/root/packages/builder

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