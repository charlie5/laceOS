#!/bin/bash

set -e

sudo rm -fr profile/airootfs/root/packages/aur/*
sudo rm -fr profile/airootfs/root/packages/pacstrap/*
sudo rm -fr profile/airootfs/root/custom/var/cache/pacman/pkg/*

echo Done.