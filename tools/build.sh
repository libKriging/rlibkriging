#!/usr/bin/env bash
set -eo pipefail
export DEBUG_CI=true

if [[ "$DEBUG_CI" == "true" ]]; then
  set -x
fi

#ARCH=$(uname -s)
#echo "Ready to build for $ARCH in $PWD"
#case $ARCH in
#  Linux)
#    BUILD_NAME="r-linux-macos"
#    ;;
#  Darwin)
#    BUILD_NAME="r-linux-macos"
#    ;;
#  MSYS_NT*|MINGW64_NT*) # Windows
#    BUILD_NAME="r-windows"
#    ;;
#  *)
#    echo "Unknown OS [$ARCH]"
#    exit 1
#    ;;
#esac

# Setup used/unused bindings
export ENABLE_R_BINDING=ON
export ENABLE_OCTAVE_BINDING=OFF
export ENABLE_MATLAB_BINDING=OFF
export ENABLE_PYTHON_BINDING=OFF

## General build
cd inst/libKriging
# windows environment requires to load special tools
loadenv_sh=".travis-ci/${BUILD_NAME}/loadenv.sh"
if [ -e "$loadenv_sh" ]; then
  . "$loadenv_sh"
fi
#.travis-ci/${BUILD_NAME}/install.sh
.travis-ci/common/before_script.sh
cd ../..

export MAKE_SHARED_LIBS=on

MODE=${MODE:-Release}
CIDIR="${PWD}/inst/libKriging/.travis-ci/"

BUILD_TEST=false \
    MODE=${MODE} \
    CC=$(R CMD config CC) \
    CXX=$(R CMD config CXX) \
    EXTRA_CMAKE_OPTIONS="-DBUILD_SHARED_LIBS=${MAKE_SHARED_LIBS} ${EXTRA_CMAKE_OPTIONS}" \
    "${CIDIR}"/linux-macos/build.sh

export LIBKRIGING_PATH=${PWD}/inst/libKriging/${BUILD_DIR:-build}/installed
export PATH=${LIBKRIGING_PATH}/bin:${PATH}

NPROC=1
if ( command -v nproc >/dev/null 2>&1 ); then
  NPROC=$(nproc)
fi

## R build
cd inst/libKriging/bindings/R
make uninstall || true
make clean
MAKEFLAGS=-j${NPROC}
MAKE_SHARED_LIBS=${MAKE_SHARED_LIBS} make
cd ../../../..

## Copy resources from libKriging/binding/R
RLIBKRIGING_PATH="inst/libKriging/bindings/R/rlibkriging"
cp -r $RLIBKRIGING_PATH/man .
cp -r $RLIBKRIGING_PATH/R .
# Overwrite libKriging/src with ./src
cp src/* $RLIBKRIGING_PATH/src/. 
cp -r $RLIBKRIGING_PATH/src .
cp -r $RLIBKRIGING_PATH/tests .
cp -r $RLIBKRIGING_PATH/NAMESPACE .

## Cleanup resources
rm -rf inst/libKriging