#!/bin/bash

set -E

echo "$IP"
rsync -av rod@"$IP":/eden/forge/applet/os/laceOS/applet/installer/install_laceOS \
                    /usr/local/bin

echo Done.