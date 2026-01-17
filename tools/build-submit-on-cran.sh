#!/bin/bash
rm -rf src/libK
git submodule update --init --recursive
./tools/setup.sh
cd ..
R CMD build rlibkriging
R CMD check --as-cran rlibkriging_0.9-3.tar.gz