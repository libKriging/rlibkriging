#!/usr/bin/env bash
set -eo pipefail
export DEBUG_CI=true

if [[ "$DEBUG_CI" == "true" ]]; then
  set -x
fi

# Cleanup unused (for R) libKriging deps
rm -rf libKriging/dependencies/Catch2
rm -rf libKriging/dependencies/carma
rm -rf libKriging/dependencies/pybind*
rm -rf libKriging/dependencies/optim
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

# Move required on upper path to avoid path length issues
mv libKriging/dependencies/lbfgsb_cpp libKriging/.
mkdir -p libKriging/armadillo
mv libKriging/dependencies/armadillo-code/include libKriging/armadillo/.
mv libKriging/dependencies/armadillo-code/src libKriging/armadillo/.
mv libKriging/dependencies/armadillo-code/misc libKriging/armadillo/.
mv libKriging/dependencies/armadillo-code/cmake_aux libKriging/armadillo/.
mv libKriging/dependencies/armadillo-code/CMakeLists.txt libKriging/armadillo/.
rm -rf libKriging/dependencies/armadillo-code

# Use custom CMakeList to hold these changes
cp tools/libKriging_CMakeLists.txt libKriging/CMakeLists.txt


