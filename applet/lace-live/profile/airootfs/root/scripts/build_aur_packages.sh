#!/bin/bash

set -e

pikaur -S --noconfirm --rebuild gprbuild

#FLAGS="-S --noconfirm --rebuild"
FLAGS="-S --noconfirm --disable-download-timeout"

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

pikaur $FLAGS cpu-x
pikaur $FLAGS fswatch
pikaur $FLAGS libiconv
pikaur $FLAGS lightdm-settings
pikaur $FLAGS pikaur
pikaur $FLAGS yay
pikaur $FLAGS smartgit
pikaur $FLAGS timeshift

pikaur $FLAGS adacurses
#pikaur $FLAGS adasockets
pikaur $FLAGS ada_language_server
pikaur $FLAGS ada-libfswatch
pikaur $FLAGS ada_spawn
pikaur $FLAGS ada-web-server
pikaur $FLAGS ahven
pikaur $FLAGS aunit
pikaur $FLAGS florist
pikaur $FLAGS gnatdoc
#pikaur $FLAGS gnatstudio-bin
pikaur $FLAGS gnatstudio
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

#pikaur $FLAGS spark2014

#pikaur $FLAGS alt-ergo
pikaur $FLAGS z3
pikaur $FLAGS cvc4

pikaur $FLAGS gnatcoverage-bin
pikaur $FLAGS drawio-desktop
pikaur $FLAGS kazakov_simple_components

pikaur $FLAGS adaogg
pikaur $FLAGS vulkada

echo All AUR packages built.