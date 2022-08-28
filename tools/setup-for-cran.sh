#!/usr/bin/env bash
set -eo pipefail

if [[ "$DEBUG_CI" == "true" ]]; then
  set -x
fi

LIBKRIGING_SRC_PATH=src/libK

# Cleanup unused (for R) libKriging deps
rm -rf $LIBKRIGING_SRC_PATH/dependencies/Catch2
rm -rf $LIBKRIGING_SRC_PATH/dependencies/carma
rm -rf $LIBKRIGING_SRC_PATH/dependencies/pybind11
rm -rf $LIBKRIGING_SRC_PATH/dependencies/optim
rm -rf $LIBKRIGING_SRC_PATH/docs
 # then remove LinearRegressionOptim example
sed -i.bak "s/LinearRegression/##LinearRegression/g" $LIBKRIGING_SRC_PATH/src/lib/CMakeLists.txt
rm -f $LIBKRIGING_SRC_PATH/src/lib/CMakeLists.txt.bak
 
rm -f $LIBKRIGING_SRC_PATH/bindings/R/rlibkriging/src/linear_regression*
 # & unsuitable tests
rm -f $LIBKRIGING_SRC_PATH/bindings/R/rlibkriging/tests/testthat/test-binding-consistency.R

# Move required on upper path to avoid path length issues
if [ -d $LIBKRIGING_SRC_PATH/dependencies/lbfgsb_cpp ]; then
  rm -fr $LIBKRIGING_SRC_PATH/lbfgsb_cpp
  mv $LIBKRIGING_SRC_PATH/dependencies/lbfgsb_cpp $LIBKRIGING_SRC_PATH/.
  rm -rf $LIBKRIGING_SRC_PATH/dependencies/lbfgsb_cpp
elif [ ! -d $LIBKRIGING_SRC_PATH/lbfgsb_cpp ]; then
  echo "Cannot migrate lbfgsb_cpp dependency"
  exit 1
fi

if [ -d $LIBKRIGING_SRC_PATH/dependencies/armadillo-code ]; then
  rm -fr $LIBKRIGING_SRC_PATH/armadillo
  mkdir -p $LIBKRIGING_SRC_PATH/armadillo
  mv $LIBKRIGING_SRC_PATH/dependencies/armadillo-code/include $LIBKRIGING_SRC_PATH/armadillo/.
  mv $LIBKRIGING_SRC_PATH/dependencies/armadillo-code/src $LIBKRIGING_SRC_PATH/armadillo/.
  mv $LIBKRIGING_SRC_PATH/dependencies/armadillo-code/misc $LIBKRIGING_SRC_PATH/armadillo/.
  mv $LIBKRIGING_SRC_PATH/dependencies/armadillo-code/cmake_aux $LIBKRIGING_SRC_PATH/armadillo/.
  mv $LIBKRIGING_SRC_PATH/dependencies/armadillo-code/CMakeLists.txt $LIBKRIGING_SRC_PATH/armadillo/.
  rm -rf $LIBKRIGING_SRC_PATH/dependencies/armadillo-code
elif [ ! -d $LIBKRIGING_SRC_PATH/armadillo ]; then
  echo "Cannot migrate armadillo dependency"
  exit 1
fi
rm -fr $LIBKRIGING_SRC_PATH/dependencies

# Use custom CMakeList to hold these changes
cp tools/libKriging_CMakeLists.txt $LIBKRIGING_SRC_PATH/CMakeLists.txt

# .travis-ci -> travis-ci (hidden files not allowed in CRAN)
mv $LIBKRIGING_SRC_PATH/.travis-ci $LIBKRIGING_SRC_PATH/travis-ci
find $LIBKRIGING_SRC_PATH -type f -exec sed -i.bak "s/.travis-ci/travis-ci/g" {} +
