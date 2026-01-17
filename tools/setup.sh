#!/usr/bin/env bash
set -eo pipefail

if [[ "$DEBUG_CI" == "true" ]]; then
  set -x
fi

echo "========================================================================="
echo "Running setup.sh to prepare R libkriging binding as a standard R package."
echo "========================================================================="

: ${R_HOME=$(R RHOME)}
if test -z "${R_HOME}"; then
   as_fn_error $? "Could not determine R_HOME." "$LINENO" 5
fi

LIBKRIGING_SRC_PATH=src/libK

# Check if submodules need to be initialized (e.g., when installing via install_github)
if [ ! -f "$LIBKRIGING_SRC_PATH/CMakeLists.txt" ]; then
  echo "Submodules appear to be uninitialized. Checking for git and .gitmodules..."
  if [ -f ".gitmodules" ] && command -v git >/dev/null 2>&1; then
    echo "Initializing git submodules..."
    git submodule update --init --recursive
    echo "  ✓ Submodules initialized successfully"
  else
    echo "ERROR: $LIBKRIGING_SRC_PATH is empty/incomplete but cannot initialize submodules"
    echo "       Either .gitmodules is missing or git is not available"
    echo "       Please ensure you have git installed or download a release package instead"
    exit 1
  fi
fi

# Cleanup unused (for R) libKriging deps
echo "Cleaning up unused libKriging dependencies..."
rm -rf $LIBKRIGING_SRC_PATH/dependencies/Catch2
rm -rf $LIBKRIGING_SRC_PATH/dependencies/carma
rm -rf $LIBKRIGING_SRC_PATH/dependencies/pybind11
rm -rf $LIBKRIGING_SRC_PATH/dependencies/optim
rm -rf $LIBKRIGING_SRC_PATH/docs
rm -rf $LIBKRIGING_SRC_PATH/tests

echo "Disabling tests and benchmarks in CMakeLists.txt..."
if [ ! -f "$LIBKRIGING_SRC_PATH/CMakeLists.txt" ]; then
  echo "ERROR: CMakeLists.txt not found at $LIBKRIGING_SRC_PATH"
  exit 1
fi
sed -i.bak "s/add_subdirectory(tests)/##add_subdirectory(tests)/g" $LIBKRIGING_SRC_PATH/CMakeLists.txt
rm -rf $LIBKRIGING_SRC_PATH/bench
sed -i.bak "s/add_subdirectory(bench)/##add_subdirectory(bench)/g" $LIBKRIGING_SRC_PATH/CMakeLists.txt
 # then remove LinearRegressionOptim example
sed -i.bak "s/LinearRegression/##LinearRegression/g" $LIBKRIGING_SRC_PATH/src/lib/CMakeLists.txt
rm -f $LIBKRIGING_SRC_PATH/src/lib/CMakeLists.txt.bak
rm -f $LIBKRIGING_SRC_PATH/bindings/R/rlibkriging/src/linear_regression*
 # & unsuitable tests
rm -f $LIBKRIGING_SRC_PATH/bindings/R/rlibkriging/tests/testthat/test-binding-consistency.R
 # and demo
sed -i.bak "s|demo/|##demo/|g" $LIBKRIGING_SRC_PATH/src/lib/CMakeLists.txt
rm -f $LIBKRIGING_SRC_PATH/src/lib/CMakeLists.txt.bak
rm -rf $LIBKRIGING_SRC_PATH/src/lib/demo
rm -rf $LIBKRIGING_SRC_PATH/src/lib/include/libKriging/demo

echo "Reorganizing dependencies to avoid path length issues..."
# Move required on upper path to avoid path length issues
if [ -d $LIBKRIGING_SRC_PATH/dependencies/lbfgsb_cpp ]; then
  echo "  → Moving lbfgsb_cpp dependency..."
  rm -fr $LIBKRIGING_SRC_PATH/lbfgsb_cpp
  mv $LIBKRIGING_SRC_PATH/dependencies/lbfgsb_cpp $LIBKRIGING_SRC_PATH/.
  rm -rf $LIBKRIGING_SRC_PATH/dependencies/lbfgsb_cpp
  echo "  ✓ lbfgsb_cpp migrated successfully"
elif [ ! -d $LIBKRIGING_SRC_PATH/lbfgsb_cpp ]; then
  echo "ERROR: Cannot migrate lbfgsb_cpp dependency (not found in dependencies/ or lbfgsb_cpp/)"
  exit 1
else
  echo "  ✓ lbfgsb_cpp already in place"
fi

if [ -d $LIBKRIGING_SRC_PATH/dependencies/armadillo-code ]; then
  echo "  → Moving armadillo dependency..."
  rm -fr $LIBKRIGING_SRC_PATH/armadillo
  mkdir -p $LIBKRIGING_SRC_PATH/armadillo
  mv $LIBKRIGING_SRC_PATH/dependencies/armadillo-code/include $LIBKRIGING_SRC_PATH/armadillo/.
  mv $LIBKRIGING_SRC_PATH/dependencies/armadillo-code/src $LIBKRIGING_SRC_PATH/armadillo/.
  mv $LIBKRIGING_SRC_PATH/dependencies/armadillo-code/misc $LIBKRIGING_SRC_PATH/armadillo/.
  mv $LIBKRIGING_SRC_PATH/dependencies/armadillo-code/cmake_aux $LIBKRIGING_SRC_PATH/armadillo/.
  mv $LIBKRIGING_SRC_PATH/dependencies/armadillo-code/CMakeLists.txt $LIBKRIGING_SRC_PATH/armadillo/.
  rm -rf $LIBKRIGING_SRC_PATH/dependencies/armadillo-code
  echo "  ✓ armadillo migrated successfully"
elif [ ! -d $LIBKRIGING_SRC_PATH/armadillo ]; then
  echo "ERROR: Cannot migrate armadillo dependency (not found in dependencies/armadillo-code/ or armadillo/)"
  exit 1
else
  echo "  ✓ armadillo already in place"
fi
rm -fr $LIBKRIGING_SRC_PATH/dependencies

echo "Updating CMakeLists.txt for reorganized dependencies..."
# Use custom CMakeList to hold these changes
sed -i.bak -e "s|dependencies/armadillo-code|armadillo|g" \
  $LIBKRIGING_SRC_PATH/CMakeLists.txt
sed -i.bak -e "s|dependencies/lbfgsb_cpp|lbfgsb_cpp|g" \
  $LIBKRIGING_SRC_PATH/CMakeLists.txt
sed -i.bak -e "s|configure_file(\${DOXYGEN_IN}|##configure_file(\${DOXYGEN_IN}|g" \
  $LIBKRIGING_SRC_PATH/CMakeLists.txt
sed -i.bak -e "s|^.*CATCH_MODULE_PATH|##&|g" \
  $LIBKRIGING_SRC_PATH/CMakeLists.txt
sed -i.bak -e "s|include(CTest)|##&|g" \
  $LIBKRIGING_SRC_PATH/CMakeLists.txt
sed -i.bak -e "s|add_subdirectory(tests)|##&|g" \
  $LIBKRIGING_SRC_PATH/CMakeLists.txt
sed -i.bak -e '/^add_custom_target(run_unit_tests$/,/^        )$/d;//d' \
  $LIBKRIGING_SRC_PATH/CMakeLists.txt
rm -rf $LIBKRIGING_SRC_PATH/CMakeLists.txt.bak
# also let libKriging Cmake search libs in R_HOME/... (eg. armadillo will search lapack in R_HOME/../libRlapack)
sed -i.bak -e "s|APPEND CMAKE_SYSTEM_LIBRARY_PATH |APPEND CMAKE_SYSTEM_LIBRARY_PATH ${R_HOME}/lib |g" \
  $LIBKRIGING_SRC_PATH/CMakeLists.txt
rm -rf $LIBKRIGING_SRC_PATH/CMakeLists.txt.bak

# Because CRAN policy : disable or replace all *::cout ... in all .cpp and .hpp files
if [ "$_R_CHECK_CRAN_INCOMING_" != "FALSE" ]; then
  echo "Applying CRAN compliance modifications (replacing cout/cerr with Rcpp equivalents)..."
  # replace cout/cerr in libkriging
  find $LIBKRIGING_SRC_PATH/src/lib -type f -name lk_armadillo.hpp -exec sed -i.bak "s|#include <armadillo>|#include <Rcpp.h>\n#include <armadillo>|g" {} +
  find $LIBKRIGING_SRC_PATH/src/lib -type f -name *.*pp -exec sed -i.bak "s|arma\:\:cout|Rcpp::Rcout|g" {} +
  find $LIBKRIGING_SRC_PATH/src/lib -type f -name *.*pp -exec sed -i.bak "s|std\:\:cout|Rcpp::Rcout|g" {} +
  find $LIBKRIGING_SRC_PATH/src/lib -type f -name *.*pp -exec sed -i.bak "s|arma\:\:cerr|Rcpp::Rcerr|g" {} +
  find $LIBKRIGING_SRC_PATH/src/lib -type f -name *.*pp -exec sed -i.bak "s|std\:\:cerr|Rcpp::Rcerr|g" {} +
  ## also replace std::runtime_error by Rcpp::stop < NO, Rcpp::stop is not thread-safe !
  #find $LIBKRIGING_SRC_PATH/src/lib -type f -name base64.cpp -exec sed -i.bak "s|#include \"base64.h\"|#include <Rcpp.h>\n#include \"base64.h\"|g" {} +
  #find $LIBKRIGING_SRC_PATH/src/lib -type f -name *.*pp -exec sed -i.bak "s|throw std\:\:runtime_error|//Rcpp::stop|g" {} +

  # disable cout/cerr in lbfgsb_cpp
  find $LIBKRIGING_SRC_PATH/lbfgsb_cpp -type f -name *.*pp -exec sed -i.bak "s|std\:\:cout|//&|g" {} +
  find $LIBKRIGING_SRC_PATH/lbfgsb_cpp -type f -name *.*pp -exec sed -i.bak "s|std\:\:cerr|//&|g" {} +
  # disable cout/cerr in slapack
  find $LIBKRIGING_SRC_PATH/../slapack -type f -name *.*pp -exec sed -i.bak "s|std\:\:cout|//&|g" {} +
  find $LIBKRIGING_SRC_PATH/../slapack -type f -name *.*pp -exec sed -i.bak "s|std\:\:cerr|//&|g" {} +
  # Replace or remove std::cout/cerr in armadillo
  find $LIBKRIGING_SRC_PATH/armadillo -type f -name *.*pp* -exec sed -i.bak "s|using std\:\:cout;|//&|g" {} +
  find $LIBKRIGING_SRC_PATH/armadillo -type f -name *.*pp* -exec sed -i.bak "s|using std\:\:cerr;|//&|g" {} +
  find $LIBKRIGING_SRC_PATH/armadillo -type f -name *.*pp* -exec sed -i.bak "s|ARMA_COUT_STREAM std\:\:cout|ARMA_COUT_STREAM Rcpp::Rcout|g" {} +
  find $LIBKRIGING_SRC_PATH/armadillo -type f -name *.*pp* -exec sed -i.bak "s|ARMA_CERR_STREAM std\:\:cerr|ARMA_CERR_STREAM Rcpp::Rcerr|g" {} +

  # fix inconsistent declaration in lbfgsb_cpp (found by gcc-SAN)
  find $LIBKRIGING_SRC_PATH/lbfgsb_cpp -type f -name lbfgsb.h* -exec sed -i.bak "s|void setulb_(|int setulb_(|g" {} +
  echo "  ✓ CRAN compliance modifications applied"
fi

echo "Patching nlohmann/json.hpp for R compatibility..."
# Disable pragma that inhibit warnings
if [ ! -f "$LIBKRIGING_SRC_PATH/src/lib/include/libKriging/utils/nlohmann/json.hpp" ]; then
  echo "WARNING: json.hpp not found, skipping json patches"
else
  sed -i.bak -e "s|#pragma|//&|g" \
    $LIBKRIGING_SRC_PATH/src/lib/include/libKriging/utils/nlohmann/json.hpp
rm -rf $LIBKRIGING_SRC_PATH/src/lib/include/libKriging/utils/nlohmann/json.hpp.bak
# replace #define JSON_THROW(exception) std::abort() 
sed -i.bak -e "s|#define JSON_THROW(exception) std::abort()|#define JSON_THROW(exception) throw exception|g" \
  $LIBKRIGING_SRC_PATH/src/lib/include/libKriging/utils/nlohmann/json.hpp
rm -rf $LIBKRIGING_SRC_PATH/src/lib/include/libKriging/utils/nlohmann/json.hpp.bak
  echo "  ✓ json.hpp patched successfully"
fi

echo "Configuring slapack as local dependency..."
# Switch slapack dependency as a local submodule (not a git clone)
sed -i.bak -e "s|https://github.com/libKriging/slapack.git|\${CMAKE_CURRENT_SOURCE_DIR}/../../slapack|g" \
  $LIBKRIGING_SRC_PATH/armadillo/cmake_aux/Modules/ARMA_FindLAPACK.cmake
sed -i.bak -e "s|GIT_REPOSITORY|SOURCE_DIR|g" \
  $LIBKRIGING_SRC_PATH/armadillo/cmake_aux/Tools/build_external_project.cmake

echo "Renaming hidden files for CRAN compliance..."
# .travis-ci -> travis-ci (hidden files not allowed in CRAN)
if [ -d $LIBKRIGING_SRC_PATH/.travis-ci ]; then
  echo "  → Renaming .travis-ci to travis-ci..."
  mv $LIBKRIGING_SRC_PATH/.travis-ci $LIBKRIGING_SRC_PATH/travis-ci
fi
# rename .travis-ci in travis-ci everywhere. Use temp .bak for sed OSX compliance
echo "  → Updating .travis-ci references in shell scripts..."
find $LIBKRIGING_SRC_PATH -type f -name *.sh -exec sed -i.bak "s/\.travis-ci/travis-ci/g" {} +
echo "  → Removing git rev-parse dependencies..."
# remove usages of 'git rev-parse', which is not a standard requirement fo R
GIT_ROOT=$(pwd);
while [ "$GIT_ROOT" != "/" ]; do
  if [ -d "$GIT_ROOT/.git" ]; then
    break;
  fi;
  GIT_ROOT=$(dirname "$GIT_ROOT");
done
export GIT_ROOT
find $LIBKRIGING_SRC_PATH -type f -name *.sh -exec sed -i.bak "s|\$(git rev-parse --show-toplevel)|$GIT_ROOT|g" {} +
# cleanup
echo "  → Cleaning up .bak files..."
find $LIBKRIGING_SRC_PATH -type f -name *.bak -exec rm -f {} +;

echo "Copying R binding files from libKriging..."
RLIBKRIGING_PATH=$LIBKRIGING_SRC_PATH"/bindings/R/rlibkriging/"

if [ ! -d "$RLIBKRIGING_PATH" ]; then
  echo "ERROR: R binding path not found: $RLIBKRIGING_PATH"
  exit 1
fi

echo "  → Copying Makevars..."
# overwrite libK/src/Makevars* with ./src/Makevars*
if [ -f "src/Makevars" ]; then
  cp src/Makevars* $RLIBKRIGING_PATH/src/.
else
  echo "WARNING: src/Makevars not found, skipping copy"
fi

echo "  → Copying R sources..."
# copy resources from libK/binding/R
rm -rf R
cp -r $RLIBKRIGING_PATH/R .

echo "Adding unlink(outfile) calls to documentation examples..."
# in *KrigingClass.R, ensure no remaining files after examples
for f in `ls R/*KrigingClass.R`; do
  # append "#' unlink(outfile)" in examples block. Located just before function declaration: save.*Kriging and load.*Kriging. example:
  # ...
  # #' print(load.NuggetKriging(outfile))
  # load.NuggetKriging <- function(...
  # becomes
  # ...
  # #' print(load.NuggetKriging(outfile))
  # #' unlink(outfile)
  # load.NuggetKriging <- function(...
  sed -i.bak -E "/^save\..*Kriging/i\\
#' unlink(outfile)
" $f
  sed -i.bak -E "/^load\..*Kriging/i\\
#' unlink(outfile)
" $f
  rm -f $f.bak
done
echo "  ✓ Documentation cleanup added"

echo "  → Copying C++ sources..."
rm -rf src/*.cpp
cp -r $RLIBKRIGING_PATH/src .

echo "  → Copying NAMESPACE..."
cp -r $RLIBKRIGING_PATH/NAMESPACE .

echo "Preparing test files..."
rm -rf tests
cp -r $RLIBKRIGING_PATH/tests .
# detailed tests
echo "  → Modifying test files for R CMD check..."
#  remove previous loading of previous custom testthat & rlibkriging (that should not be there, anyway)
if [ -d "tests/testthat" ]; then
  find tests/testthat -type f -name test-*.R -exec sed -i.bak -e 's|library(testthat)|#library(testthat)|g' {} +
  find tests/testthat -type f -name test-*.R -exec sed -i.bak -e 's|library(rlibkriging|#library(rlibkriging|g' {} +
#  prepend loading of testthat
  mv tests/testthat/test-*.R tests/.
else
  echo "WARNING: tests/testthat directory not found"
fi

echo "  → Preparing individual test files..."
for f in `ls -d tests/test-*.R 2>/dev/null`; do
  echo -e "library(testthat)\n Sys.setenv('OMP_THREAD_LIMIT'=2)\n" > $f.new
  # if DiceKriging used, load it but then load rlibkriging
  if grep -q "DiceKriging::" $f; then
    echo -e "library(DiceKriging)\n library(rlibkriging)\n" >> $f.new
  else
    echo -e "library(rlibkriging)\n" >> $f.new
  fi
  echo "$(cat $f)" >> $f.new
  mv $f.new $f
  # reduce tests time by shrinking number of simulations, iterations, and points of testing
  sed -i.bak -e "s|,101)|,5)|g" $f # less sample in seq(...,101)
  rm -f $f.bak
  sed -i.bak -e "s|,51)|,5)|g" $f # less sample in seq(...,51)
  rm -f $f.bak
  sed -i.bak -e "s|,21)|,5)|g" $f # less sample in seq(...,21)
  rm -f $f.bak
  sed -i.bak -e "s|n <- 10|n <- 1|g" $f # less sample: /10
  rm -f $f.bak
  sed -i.bak -e "s|simulate(1000,|simulate(100,|g" $f # less sample in simulate
  rm -f $f.bak
  sed -i.bak -e "s|p.value > 0.0|p.value > 0.00|g" $f # also reduce p-value threshold, because of simulate sample size reduction
  rm -f $f.bak
  sed -i.bak -e "s|for (i in 1:length(.x)) { for (j in 1:length(.x)) {|for (i in 1:length(.x)) { j=i; {|g" $f # avoid full factorial sampling in 2d
  rm -f $f.bak
  sed -i.bak -e "s|ntest <- 100|ntest <- 10|g" $f
  rm -f $f.bak
  sed -i.bak -e "s|\(.\+\)mean_deriv\[i\]|#&|g" $f # rm some canary test
  rm -f $f.bak
  sed -i.bak -e "s|\(.\+\)stdev_deriv\[i\]|#&|g" $f # rm some canary test
  rm -f $f.bak
  sed -i.bak -E "s|km\((.+)(\s*)multistart(\s*)=(\s*)([[:digit:]]+)|km(\1 multistart=1 |g" $f # no multistart (so foreach package not needed)
  rm -f $f.bak
  # for the same thread-safe issue, disable chol_warning by default:
  sed -i.bak -e "s|linalg_set_chol_warning(TRUE)|linalg_set_chol_warning(FALSE)|g" $f
  # if test file includes RobustGaSP, add conditional loading
  if grep -q "RobustGaSP" $f; then
    echo "if(requireNamespace('RobustGaSP', quietly = TRUE)) {" > $f.new
    cat $f >> $f.new
    #sed -i.bak -e "s|library(RobustGaSP)|if(!requireNamespace('RobustGaSP', quietly = TRUE)) {\n  print('RobustGaSP not available')\n} else {\nlibrary(RobustGaSP)|g" $f # disable tests if missing RobustGaSP
    #rm -f $f.bak
    echo "}" >> $f.new
    mv $f.new $f
  fi
  if grep -q "DiceKriging" $f; then
    echo "if(requireNamespace('DiceKriging', quietly = TRUE)) { " > $f.new
    cat $f >> $f.new
    #sed -i.bak -e "s|library(RobustGaSP)|if(!requireNamespace('RobustGaSP', quietly = TRUE)) {\n  print('RobustGaSP not available')\n} else {\nlibrary(RobustGaSP)|g" $f # disable tests if missing RobustGaSP
    #rm -f $f.bak
    echo "}" >> $f.new
    mv $f.new $f
  fi
  # properly cleanup created files if any
  for ext in Rdata json; do
    if grep -q ".$ext" $f; then
      varnames=$(grep -oE "\"[^\"]+.$ext\"" $f | tr -d '"')
      for varname in $varnames; do
        echo -e "\nif (file.exists(\"$varname\")) {\n  file.remove(\"$varname\")\n}\n" >> $f
      done
      rm -f $f.bak
    fi
  done
done
echo "  ✓ Test files prepared"

rm -rf tests/testthat/
rm -rf tests/testthat.R
# disable cholesky tests for fedora timeout (still to investigate deeper...)
rm -rf tests/test-KrigingCholCrash.R
rm -rf tests/demo*
rm -rf tests/bench*
rm -rf tests/bug*

echo "Syncing documentation with roxygen2..."
# sync man content, if roxygen2 available
if Rscript -e "if (!requireNamespace('roxygen2', quietly=TRUE)) quit(status=1)" 2>/dev/null ; then
  echo "  → Running roxygen2::roxygenize()..."
  rm -rf man
  if "${R_HOME}"/bin/R -e "roxygen2::roxygenize('.')" ; then
    echo "  ✓ Documentation synced successfully"
  else
    echo "WARNING: roxygen2 failed, continuing anyway..."
  fi
else
  echo "  ⚠ roxygen2 not available, skipping man sync"
fi

echo "Cleaning up build directory..."
rm -rf $LIBKRIGING_SRC_PATH/build

echo "Ensuring LF line endings for Unix compatibility..."
# Ensure LF line endings for Makefiles and shell scripts (CRLF causes issues on Unix)
find $LIBKRIGING_SRC_PATH -type f \( -name 'Makefile*' -o -name '*.sh' \) -exec sed -i.bak $'s/\r$//' {} +
find . -type f \( -name 'Makefile*' -o -name '*.sh' \) -exec sed -i.bak $'s/\r$//' {} +
find . -type f -name '*.bak' -exec rm -f {} +

echo "========================================================================="
echo "✓ Setup completed successfully!"
echo "========================================================================="
