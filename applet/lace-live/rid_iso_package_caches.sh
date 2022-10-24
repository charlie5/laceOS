#!/bin/bash

set -e

sudo rm -fr profile/airootfs/root/aur/*
sudo rm -fr profile/airootfs/root/custom/var/cache/pacman/pkg/*
sudo rm -fr profile/airootfs/root/pacstrap_packages/*

echo Done.