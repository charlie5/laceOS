#!/bin/bash

set -e

./rid_iso.sh
./build_iso.sh
./export_iso.sh

echo Rebuild done.