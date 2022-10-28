#!/bin/bash

set -e

mount /dev/sda2 /mnt

rm -fr /mnt/root/packages/aur/*
rm -fr /mnt/var/cache/pacman/pkg/*

umount /mnt

echo Installed package caches cleared.