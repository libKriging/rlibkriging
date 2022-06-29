#!/usr/bin/env bash
set -eo pipefail
export DEBUG_CI=true

if [[ "$DEBUG_CI" == "true" ]]; then
  set -x
fi


# Setup used/unused bindings
export ENABLE_R_BINDING=ON
export ENABLE_OCTAVE_BINDING=OFF
export ENABLE_MATLAB_BINDING=OFF
export ENABLE_PYTHON_BINDING=OFF


# General build
cd inst/libKriging

{
.travis-ci/common/before_script.sh
} || {
echo "!!! Failed checking configuration !!!"
}

export MAKE_SHARED_LIBS=off

NPROC=1
if ( command -v nproc >/dev/null 2>&1 ); then
  NPROC=$(nproc)
fi
MAKEFLAGS=-j${NPROC}

# arch dependant options
ARCH=$(uname -s)
echo "Ready to build for $ARCH in $PWD"
case $ARCH in
  Linux)
    ;;
  Darwin)
    ;;
  MSYS_NT*|MINGW64_NT*) # Windows
      # OpenBLAS installation
      export EXTRA_SYSTEM_LIBRARY_PATH=""
      #/C/Miniconda3/Library/lib
      export EXTRA_CMAKE_OPTIONS="-fopenmp"
      export MAKE_SHARED_LIBS=on
      unset MAKEFLAGS
    ;;
  *)
    echo "Unknown OS [$ARCH]"
    exit 1
    ;;
esac

MODE=${MODE:-Release}

BUILD_TEST=false \
    MODE=${MODE} \
    CC=$(R CMD config CC) \
    CXX=$(R CMD config CXX) \
    FC=$(R CMD config FC) \
    EXTRA_CMAKE_OPTIONS="-DBUILD_SHARED_LIBS=${MAKE_SHARED_LIBS} ${EXTRA_CMAKE_OPTIONS} -DEXTRA_SYSTEM_LIBRARY_PATH=${EXTRA_SYSTEM_LIBRARY_PATH} " \
    ${PWD}/.travis-ci/linux-macos/build.sh

cd ../..


# R build
export LIBKRIGING_PATH=${PWD}/inst/libKriging/${BUILD_DIR:-build}/installed
export PATH=${LIBKRIGING_PATH}/bin:${PATH}

cd inst/libKriging/bindings/R
make uninstall || true
make clean
MAKE_SHARED_LIBS=${MAKE_SHARED_LIBS} make
cd ../../../..


# Copy resources from libKriging/binding/R
RLIBKRIGING_PATH="inst/libKriging/bindings/R/rlibkriging"
cp -r $RLIBKRIGING_PATH/man .
cp -r $RLIBKRIGING_PATH/R .
cp src/* $RLIBKRIGING_PATH/src/. # overwrite libKriging/src with ./src
cp -r $RLIBKRIGING_PATH/src .
cp -r $RLIBKRIGING_PATH/tests .
cp -r $RLIBKRIGING_PATH/NAMESPACE .


# Cleanup resources
rm -rf inst/libKriging