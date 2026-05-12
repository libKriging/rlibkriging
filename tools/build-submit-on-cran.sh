#!/bin/bash
set -e
SCRIPT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$SCRIPT_DIR"
rm -rf src/libK
git submodule update --init --recursive
./tools/setup.sh
R CMD build .
PKG_FILE=$(ls rlibkriging_*.tar.gz | sort -V | tail -1)
R CMD check --as-cran "$PKG_FILE"