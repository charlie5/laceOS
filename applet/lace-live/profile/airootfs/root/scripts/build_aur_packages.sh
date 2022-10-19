#!/bin/bash

set -e

#mount /dev/vda2 /mnt
#mount /dev/vda1 /mnt/boot

#arch-chroot /mnt -u rod 

#su - rod


#rm -fr /tmp/makepkg
#rm -fr ~/.cache/pikaur
#mv ~/.cache/pikaur ~/.cache/pikaur-original

pikaur -S --noconfirm --rebuild gprbuild

#FLAGS="-S --noconfirm --rebuild"
FLAGS="-S --noconfirm"

pikaur $FLAGS gnatcoll-core
pikaur $FLAGS alire
pikaur $FLAGS gnatcoll-db2ada
pikaur $FLAGS gnatcoll-gnatinspect
pikaur $FLAGS gnatcoll-postgres
pikaur $FLAGS gnatcoll-sql
pikaur $FLAGS gnatcoll-sqlite
pikaur $FLAGS gnatcoll-xref

pikaur $FLAGS gnatcoll-gmp      \
              gnatcoll-iconv    \
              gnatcoll-lzma     \
              gnatcoll-omp      \
              gnatcoll-python   \
              gnatcoll-readline \
              gnatcoll-syslog   \
              gnatcoll-zlib

#pikaur $FLAGS gnatcoll-python3

pikaur $FLAGS cpu-x
pikaur $FLAGS fswatch
pikaur $FLAGS libiconv
pikaur $FLAGS lightdm-settings
pikaur $FLAGS pikaur
pikaur $FLAGS smartgit
pikaur $FLAGS timeshift
pikaur $FLAGS adacurses
pikaur $FLAGS ada_language_server
pikaur $FLAGS ada-libfswatch
pikaur $FLAGS ada_spawn
pikaur $FLAGS ada-web-server
pikaur $FLAGS ahven
pikaur $FLAGS aunit
pikaur $FLAGS florist
pikaur $FLAGS gnatstudio-bin
pikaur $FLAGS gnatsymbolize
pikaur $FLAGS gtkada
pikaur $FLAGS ini_file_manager
pikaur $FLAGS inotify-ada
pikaur $FLAGS langkit
pikaur $FLAGS libadalang
pikaur $FLAGS libadalang-tools
pikaur $FLAGS libgpr
pikaur $FLAGS libvss
pikaur $FLAGS polyorb
pikaur $FLAGS sdlada
pikaur $FLAGS sphinxcontrib-adadomain
pikaur $FLAGS xmlada


#rsync -av --delete ~/.cache/pikaur/pkg/ profile/airootfs/root/aur

#rm -f profile/airootfs/root/aur/gprbuild-bootstrap-*-x86_64.pkg.tar.zst
#rm -f profile/airootfs/root/aur/gnatcoll-python3-*-x86_64.pkg.tar.zst

#rm -fr ~/.cache/pikaur
#mv     ~/.cache/pikaur-original  ~/.cache/pikaur


exit
#umount -R /mnt


echo All AUR packages built.