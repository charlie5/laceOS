#!/bin/bash

set -e

sync_essential_pkgs.sh
sync_installed_pkgs.sh
sync_aur_pkgs.sh


echo All packages synced.
