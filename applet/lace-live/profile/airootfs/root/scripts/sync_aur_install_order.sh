#!/bin/bash

set -e

rsync -av /root/aur_install_order \
          rod@$IP:/eden/forge/applet/os/laceOS/applet/lace-live/profile/airootfs/root/

echo Done.