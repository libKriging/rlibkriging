#!/usr/bin/env bash
set -eo pipefail

if [[ "$DEBUG_CI" == "true" ]]; then
  set -x
fi

# Cleanup unused (for R) libKriging deps
rm -rf libKriging/dependencies/Catch2
rm -rf libKriging/dependencies/carma
rm -rf libKriging/dependencies/pybind*
rm -rf libKriging/dependencies/optim
rm -rf libKriging/docs
 # then remove LinearRegressionOptim example
case "$(uname -s)" in
 Darwin)
   sed -i"''" "s/LinearRegression/##LinearRegression/g" libKriging/src/lib/CMakeLists.txt
   ;;
 *)
   sed -i "s/LinearRegression/##LinearRegression/g" libKriging/src/lib/CMakeLists.txt
   ;;
esac
rm -f libKriging/bindings/R/rlibkriging/src/linear_regression*
 # & unsuitable tests
rm -f libKriging/bindings/R/rlibkriging/tests/testthat/test-binding-consistency.R

# Move required on upper path to avoid path length issues
if [ ! -d libKriging/lbfgsb_cpp ]; then
  mv libKriging/dependencies/lbfgsb_cpp libKriging/.
fi
if [ ! -d libKriging/armadillo ]; then
  mkdir -p libKriging/armadillo
  mv libKriging/dependencies/armadillo-code/include libKriging/armadillo/.
  mv libKriging/dependencies/armadillo-code/src libKriging/armadillo/.
  mv libKriging/dependencies/armadillo-code/misc libKriging/armadillo/.
  mv libKriging/dependencies/armadillo-code/cmake_aux libKriging/armadillo/.
  mv libKriging/dependencies/armadillo-code/CMakeLists.txt libKriging/armadillo/.
  rm -rf libKriging/dependencies/armadillo-code
fi

# Use custom CMakeList to hold these changes
cp tools/libKriging_CMakeLists.txt libKriging/CMakeLists.txt

