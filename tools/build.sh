#!/usr/bin/env bash
set -eo pipefail

ARCH=$(uname -s)
echo "Ready to build for $ARCH in $PWD"

# Setup used/unused bindings
export ENABLE_R_BINDING=ON
export ENABLE_OCTAVE_BINDING=OFF
export ENABLE_MATLAB_BINDING=OFF
export ENABLE_PYTHON_BINDING=OFF

# Use CI tasks to build
case $ARCH in
  Linux)
    BUILD_NAME="r-linux-macos"
    ;;
  Darwin)
    BUILD_NAME="r-linux-macos"
    ;;
  MSYS_NT*|MINGW64_NT*) # Windows
    BUILD_NAME="r-windows"
    ;;
  *)
    echo "Unknown OS [$ARCH]"
    exit 1
    ;;
esac

cd inst/libKriging
# windows environment requires to load special tools
loadenv_sh=".travis-ci/${BUILD_NAME}/loadenv.sh"
if [ -e "$loadenv_sh" ]; then
  . "$loadenv_sh"
fi
.travis-ci/${BUILD_NAME}/install.sh
.travis-ci/common/before_script.sh
.travis-ci/${BUILD_NAME}/build.sh
cd ../..

cp -r inst/libKriging/bindings/R/rlibkriging/man .
cp -r inst/libKriging/bindings/R/rlibkriging/R .
cp -r inst/libKriging/bindings/R/rlibkriging/src .
cp -r inst/libKriging/bindings/R/rlibkriging/tests .
cp -r inst/libKriging/bindings/R/rlibkriging/NAMESPACE .

