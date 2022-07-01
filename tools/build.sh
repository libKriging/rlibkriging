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

export MAKE_SHARED_LIBS=off


# Static libKriging build (using libKriging/.ci)
cd libKriging

{
.travis-ci/common/before_script.sh
} || {
echo "!!! Failed checking configuration !!!"
}

BUILD_TEST=false \
MODE=Release \
CC=$(R CMD config CC) \
CXX=$(R CMD config CXX) \
FC=$(R CMD config FC) \
EXTRA_CMAKE_OPTIONS="-DBUILD_SHARED_LIBS=${MAKE_SHARED_LIBS} -DEXTRA_SYSTEM_LIBRARY_PATH=${EXTRA_SYSTEM_LIBRARY_PATH}" \
${PWD}/.travis-ci/linux-macos/build.sh

mkdir -p ../inst
cp -r build/installed/lib ../inst/.
cp -r build/installed/share ../inst/.
cp -r build/installed/include ../inst/.
echo "inst/: "`ls ../inst`

cd ..


# Prepare rlibkriging build (that will follow just after this script)
RLIBKRIGING_PATH="libKriging/bindings/R/rlibkriging"

# update doc
#Rscript -e "roxygen2::roxygenise(package.dir = '$RLIBKRIGING_PATH')" # No: it will loop on install, because roxygen2 requires loading package...
# update Rccp links
Rscript -e "Rcpp::compileAttributes(pkgdir = '$RLIBKRIGING_PATH', verbose = TRUE)"

# overwrite libKriging/src/Makevars* with ./src/Makevars*
cp src/Makevars* $RLIBKRIGING_PATH/src/. 

# copy resources from libKriging/binding/R
cp -r $RLIBKRIGING_PATH/R .
cp -r $RLIBKRIGING_PATH/src .
cp -r $RLIBKRIGING_PATH/tests .
cp -r $RLIBKRIGING_PATH/man .
cp -r $RLIBKRIGING_PATH/NAMESPACE .

# sync Version number
VERSION=`grep "Version:" $RLIBKRIGING_PATH/DESCRIPTION`
case "$(uname -s)" in
 Darwin)
   sed -i"''" "s/Version:.*/$VERSION/g" DESCRIPTION
   ;;
 *)
   sed -i "s/Version:.*/$VERSION/g" DESCRIPTION
   ;;
esac