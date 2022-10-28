#!/bin/bash

set -e

rsync -av                      \
      /var/cache/pacman/pkg/   \
      rod@$IP:/eden/forge/applet/os/laceOS/applet/lace-live/profile/airootfs/root/packages/pacstrap
      
sync

echo Done.