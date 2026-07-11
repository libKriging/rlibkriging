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
export STATIC_LIB=on

: ${R_HOME=$(R RHOME)}
if test -z "${R_HOME}"; then
   as_fn_error $? "Could not determine R_HOME." "$LINENO" 5
fi

# Static libKriging build (using libK CI scripts)
cd src/libK
# Find CI scripts directory: 'tools' (new name since libKriging PR#314), or '.travis-ci'/'travis-ci' (legacy)
if [ -d tools/common ]; then
  CI=tools
else
  CI=`ls -a | grep travis-ci`
fi
echo "CI: "$CI

{
$CI/common/before_script.sh
} || {
echo "!!! Failed checking configuration !!!"
}

export CC=`${R_HOME}/bin/R CMD config CC`
export CXX=`${R_HOME}/bin/R CMD config CXX`
export FC=`${R_HOME}/bin/R CMD config FC`

# Get CXXFLAGS and remove non-portable flag for CRAN compatibility (if not already set by configure)
if [ -z "$CXXFLAGS" ]; then
  export CXXFLAGS=`${R_HOME}/bin/R CMD config CXXFLAGS | sed 's/-mno-omit-leaf-frame-pointer//g'`
fi
if [ -z "$CFLAGS" ]; then
  export CFLAGS=`${R_HOME}/bin/R CMD config CFLAGS | sed 's/-mno-omit-leaf-frame-pointer//g'`
fi

# R workflow requires to use R cmd with full path.
# These declarations help to skip declaration without full path in libKriging build scripts.
export CMAKE_Fortran_COMPILER="$(${R_HOME}/bin/R CMD config FC | awk '{ print $1 }')"
export Fortran_LINK_FLAGS="$(${R_HOME}/bin/R CMD config FLIBS)"

if [ "$_R_CHECK_CRAN_INCOMING_" != "FALSE" ]; then
  # enable Rcout & Rcerr:
  # Get RcppArma include - use shortPathName on Windows to avoid spaces
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      # Use shortPathName to avoid spaces, then convert to forward slashes
      export RCPP_INCLUDE_PATH=$(${R_HOME}/bin/Rscript --vanilla -e "cat(gsub('\\\\\\\\', '/', shortPathName(file.path(system.file(package='Rcpp'),'include'))))")
      export R_INCLUDE_PATH=$(${R_HOME}/bin/Rscript --vanilla -e "cat(gsub('\\\\\\\\', '/', shortPathName(R.home('include'))))")
      ;;
    *)
      export RCPP_INCLUDE_PATH="$(${R_HOME}/bin/Rscript -e 'invisible(write(system.file(package="Rcpp"),stdout()))')"/include
      export R_INCLUDE_PATH="$(${R_HOME}/bin/Rscript -e 'invisible(write(R.home("include"),stdout()))')"
      ;;
  esac
  echo "build: Rcpp include path ${RCPP_INCLUDE_PATH}"
  echo "build: R include path ${R_INCLUDE_PATH}"
  sed -i.bak -e "s|enable_language(CXX)|enable_language(CXX)\nfile(TO_CMAKE_PATH \"\${RCPP_INCLUDE_PATH}\" RCPP_INCLUDE_PATH)\nfile(TO_CMAKE_PATH \"\${R_INCLUDE_PATH}\" R_INCLUDE_PATH)\ninclude_directories(\"\${RCPP_INCLUDE_PATH}\" \"\${R_INCLUDE_PATH}\")\nmessage(STATUS \"Rcpp include path \${RCPP_INCLUDE_PATH}\")\nmessage(STATUS \"R include path \${R_INCLUDE_PATH}\")|g" \
     CMakeLists.txt
  rm -rf CMakeLists.txt.bak
  EXTRA_CMAKE_OPTIONS="-DRCPP_INCLUDE_PATH=${RCPP_INCLUDE_PATH} -DR_INCLUDE_PATH=${R_INCLUDE_PATH} ${EXTRA_CMAKE_OPTIONS}"
fi

# macOS: align the static-lib build's deployment target with the one R links
# against. cmake otherwise defaults CMAKE_OSX_DEPLOYMENT_TARGET to the host OS
# (e.g. 26.4), so the static libs are "built for newer macOS than being linked"
# (e.g. 26.0); ld warns and R CMD check reports
# "checking whether package can be installed ... WARNING".
if [ "$(uname -s)" = "Darwin" ]; then
  MACOS_TARGET="${MACOSX_DEPLOYMENT_TARGET:-}"
  if [ -z "$MACOS_TARGET" ]; then
    MACOS_TARGET=$(printf '%s %s' "${CFLAGS:-}" "${CXXFLAGS:-}" | tr ' ' '\n' | sed -n 's/^-mmacosx-version-min=//p' | head -1)
  fi
  if [ -z "$MACOS_TARGET" ]; then
    MACOS_TARGET=$(${R_HOME}/bin/Rscript -e 'cat(Sys.getenv("MACOSX_DEPLOYMENT_TARGET"))' 2>/dev/null || true)
  fi
  if [ -z "$MACOS_TARGET" ]; then
    # Most reliable: ask R's own C compiler what min macOS version it targets.
    # The macro value is major*10000 + minor*100 + patch (e.g. 260000 -> 26.0).
    _min=$(printf '' | ${CC:-cc} ${CFLAGS:-} -dM -E - 2>/dev/null \
             | awk '/__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__/ {print $3; exit}')
    if [ -n "$_min" ]; then
      MACOS_TARGET="$(( _min / 10000 )).$(( (_min / 100) % 100 ))"
    fi
  fi
  if [ -n "$MACOS_TARGET" ]; then
    export MACOSX_DEPLOYMENT_TARGET="$MACOS_TARGET"
    EXTRA_CMAKE_OPTIONS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOS_TARGET} ${EXTRA_CMAKE_OPTIONS:-}"
    echo "build: macOS deployment target aligned with R -> ${MACOS_TARGET}"
  else
    echo "build: could not determine R macOS deployment target; leaving cmake default"
  fi

  # Silence the char_traits<unsigned char> deprecation emitted by newer macOS
  # libc++ for the vendored nlohmann/json specialization (a false positive from a
  # vendored dependency). Otherwise R CMD check flags it as a significant install
  # warning. Scoped to the C++ static-lib build (cmake reads CXXFLAGS).
  export CXXFLAGS="${CXXFLAGS:-} -Wno-deprecated-declarations"
fi

BUILD_TEST=false \
MODE=Release \
EXTRA_CMAKE_OPTIONS="${EXTRA_CMAKE_OPTIONS:-} -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=${MAKE_SHARED_LIBS} -DSTATIC_LIB=${STATIC_LIB} -DEXTRA_SYSTEM_LIBRARY_PATH=${EXTRA_SYSTEM_LIBRARY_PATH}" \
$CI/linux-macos/build.sh

# Clean up CMake temp directories immediately after build
find /tmp -maxdepth 1 -name "tmp.*" -type d -user $(id -u) -mmin -10 2>/dev/null | while read dir; do
  if [ -f "$dir/CMakeCache.txt" ] || [ -d "$dir/CMakeFiles" ]; then
    rm -rf "$dir" 2>/dev/null || true
  fi
done

rm -rf ../../inst
mkdir -p ../../inst
mv build/installed/lib ../../inst/.
mv build/installed/share ../../inst/.
mv build/installed/include ../../inst/.

cd ../..

# update doc
#R -e "roxygen2::roxygenise(package.dir = '.')" # No: it will loop on install, because roxygen2 requires loading package...
# update Rccp links
${R_HOME}/bin/R -e "Rcpp::compileAttributes(pkgdir = '.', verbose = TRUE)"

# Convert CRLF to LF in generated files (CMake and Rcpp generate CRLF on Windows)
if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* || "$(uname -s)" == CYGWIN* ]]; then
  # Convert in build directory
  find src/libK/build -type f \( -name 'Makefile*' -o -name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) -exec sed -i $'s/\r$//' {} + 2>/dev/null || true
  # Convert Rcpp-generated files
  find src -maxdepth 1 -type f \( -name '*.cpp' -o -name '*.h' \) -exec sed -i $'s/\r$//' {} + 2>/dev/null || true
  find R -maxdepth 1 -type f -name 'RcppExports.R' -exec sed -i $'s/\r$//' {} + 2>/dev/null || true
fi
