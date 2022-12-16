#!/bin/bash

set -e

echo Using "$IP"
rsync -av rod@"$IP":/eden/forge/applet/os/laceOS/applet/lace-live/profile/airootfs/root/packages/aur/ \
                    /root/packages/aur

echo Done.