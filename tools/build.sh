#!/usr/bin/env bash
set -eo pipefail

if [[ "$DEBUG_CI" == "true" ]]; then
  set -x
fi


# Setup used/unused bindings
export ENABLE_R_BINDING=ON
export ENABLE_OCTAVE_BINDING=OFF
export ENABLE_MATLAB_BINDING=OFF
export ENABLE_PYTHON_BINDING=OFF

export MAKE_SHARED_LIBS=off

: ${R_HOME=$(R RHOME)}
if test -z "${R_HOME}"; then
   as_fn_error $? "Could not determine R_HOME." "$LINENO" 5
fi

# Static libKriging build (using libKriging/.ci)
cd libKriging

{
.travis-ci/common/before_script.sh
} || {
echo "!!! Failed checking configuration !!!"
}

export CC=`${R_HOME}/bin/R CMD config CC`
export CXX=`${R_HOME}/bin/R CMD config CXX`
export FC=`${R_HOME}/bin/R CMD config FC`

# R workflow requires to use R cmd with full path.
# These declarations help to skip declaration without full path in libKriging build scripts.
export CMAKE_Fortran_COMPILER="$(${R_HOME}/bin/R CMD config FC | awk '{ print $1 }')"
export Fortran_LINK_FLAGS="$(${R_HOME}/bin/R CMD config FLIBS)"

BUILD_TEST=false \
MODE=Release \
EXTRA_CMAKE_OPTIONS="-DBUILD_SHARED_LIBS=${MAKE_SHARED_LIBS} -DEXTRA_SYSTEM_LIBRARY_PATH=${EXTRA_SYSTEM_LIBRARY_PATH}" \
${PWD}/.travis-ci/linux-macos/build.sh 

mkdir -p ../inst
mv build/installed/lib ../inst/.
mv build/installed/share ../inst/.
mv build/installed/include ../inst/.

cd ..


# Prepare rlibkriging build (that will follow just after this script)
RLIBKRIGING_PATH="libKriging/bindings/R/rlibkriging"

# update doc
#Rscript -e "roxygen2::roxygenise(package.dir = '$RLIBKRIGING_PATH')" # No: it will loop on install, because roxygen2 requires loading package...
# update Rccp links
${R_HOME}/bin/Rscript -e "Rcpp::compileAttributes(pkgdir = '$RLIBKRIGING_PATH', verbose = TRUE)"

# overwrite libKriging/src/Makevars* with ./src/Makevars*
cp src/Makevars* $RLIBKRIGING_PATH/src/. 

# copy resources from libKriging/binding/R
cp -r $RLIBKRIGING_PATH/R .
cp -r $RLIBKRIGING_PATH/src .
cp -r $RLIBKRIGING_PATH/tests .
cp -r $RLIBKRIGING_PATH/man .
cp -r $RLIBKRIGING_PATH/NAMESPACE .
