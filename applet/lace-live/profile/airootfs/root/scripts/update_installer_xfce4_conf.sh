#!/bin/bash

set -E

#export IP=192.168.165.253
#export IP=192.168.1.103


rsync -av --delete /root/.config/xfce4/ rod@$IP:/eden/forge/applet/os/laceOS/applet/lace-live/profile/airootfs/root/.config/xfce4

echo Done.