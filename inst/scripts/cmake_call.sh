#! /bin/sh

export ENABLE_OCTAVE_BINDING=OFF
export ENABLE_MATLAB_BINDING=OFF
export ENABLE_PYTHON_BINDING=OFF

cd inst/libKriging
.travis-ci/r-linux-macos/build.sh
cd ../..

cp -r inst/libKriging/bindings/R/rlibkriging/man .
cp -r inst/libKriging/bindings/R/rlibkriging/R .
cp -r inst/libKriging/bindings/R/rlibkriging/src .
cp -r inst/libKriging/bindings/R/rlibkriging/tests .
cp -r inst/libKriging/bindings/R/rlibkriging/NAMESPACE .

