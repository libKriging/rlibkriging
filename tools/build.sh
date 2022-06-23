#!/usr/bin/env bash
set -eo pipefail

if [[ "$DEBUG_CI" == "true" ]]; then
  set -x
fi

# windows environment requires to load special tools
loadenv_sh=".travis-ci/${BUILD_NAME}/loadenv.sh"
if [ -e "$loadenv_sh" ]; then
  . "$loadenv_sh"
fi

ARCH=$(uname -s)
echo "Ready to build for $ARCH"

# Setup used/unused bindings
export ENABLE_R_BINDING=ON
export ENABLE_OCTAVE_BINDING=OFF
export ENABLE_MATLAB_BINDING=OFF
export ENABLE_PYTHON_BINDING=OFF

# Use CI task to build
cd inst/libKriging
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
.travis-ci/${BUILD_NAME}/install.sh
.travis-ci/common/before_script.sh
.travis-ci/${BUILD_NAME}/build.sh
cd ../..

cp -r inst/libKriging/bindings/R/rlibkriging/man .
cp -r inst/libKriging/bindings/R/rlibkriging/R .
cp -r inst/libKriging/bindings/R/rlibkriging/src .
cp -r inst/libKriging/bindings/R/rlibkriging/tests .
cp -r inst/libKriging/bindings/R/rlibkriging/NAMESPACE .

