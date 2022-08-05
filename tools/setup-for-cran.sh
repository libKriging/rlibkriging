#!/usr/bin/env bash
set -eo pipefail

if [[ "$DEBUG_CI" == "true" ]]; then
  set -x
fi

# Cleanup unused (for R) libKriging deps
rm -rf libKriging/dependencies/Catch2
rm -rf libKriging/dependencies/carma
rm -rf libKriging/dependencies/pybind11
rm -rf libKriging/dependencies/optim
rm -rf libKriging/docs
 # then remove LinearRegressionOptim example
sed -i.bak "s/LinearRegression/##LinearRegression/g" libKriging/src/lib/CMakeLists.txt
rm -f libKriging/src/lib/CMakeLists.txt.bak
 
rm -f libKriging/bindings/R/rlibkriging/src/linear_regression*
 # & unsuitable tests
rm -f libKriging/bindings/R/rlibkriging/tests/testthat/test-binding-consistency.R

# Move required on upper path to avoid path length issues
if [ -d libKriging/dependencies/lbfgsb_cpp ]; then
  rm -fr libKriging/lbfgsb_cpp
  mv libKriging/dependencies/lbfgsb_cpp libKriging/.
  rm -rf libKriging/dependencies/lbfgsb_cpp
elif [ ! -d libKriging/lbfgsb_cpp ]; then
  echo "Cannot migrate lbfgsb_cpp dependency"
  exit 1
fi

if [ -d libKriging/dependencies/armadillo-code ]; then
  rm -fr libKriging/armadillo
  mkdir -p libKriging/armadillo
  mv libKriging/dependencies/armadillo-code/include libKriging/armadillo/.
  mv libKriging/dependencies/armadillo-code/src libKriging/armadillo/.
  mv libKriging/dependencies/armadillo-code/misc libKriging/armadillo/.
  mv libKriging/dependencies/armadillo-code/cmake_aux libKriging/armadillo/.
  mv libKriging/dependencies/armadillo-code/CMakeLists.txt libKriging/armadillo/.
  rm -rf libKriging/dependencies/armadillo-code
elif [ ! -d libKriging/armadillo ]; then
  echo "Cannot migrate armadillo dependency"
  exit 1
fi
rm -fr libKriging/dependencies

# Use custom CMakeList to hold these changes
cp tools/libKriging_CMakeLists.txt libKriging/CMakeLists.txt