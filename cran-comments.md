## Submission

This is a bugfix update of rlibkriging (1.2-3), submitted shortly after 1.2-2
because 1.2-2 fails to install on macOS with the flang Fortran compiler
(R-devel). No user-visible changes otherwise.

Two build issues, both only hit when `gfortran` is not available:

* `src/Makevars` linked `-lgomp` unconditionally. On macOS the bundled
  libKriging is built without OpenMP and `libgomp` is only provided by the
  gfortran runtime, so the link failed with "library 'gomp' not found". It is
  no longer linked on macOS.
* The libKriging build script looked up the Fortran compiler with a bare
  `R CMD config FC`; under `R CMD check` a bare `R` refuses to run, so the
  bundled library was silently not built and compilation failed with
  "'libKriging/utils/lkalloc.hpp' file not found". It now calls
  `${R_HOME}/bin/R`.

## Test environments

Tested locally (Ubuntu 24.04, R 4.6.1) and via GitHub Actions and R-hub on:

* Ubuntu 22.04, R release, R-devel and R oldrel-1
* macOS (Apple Silicon), R release, R-devel and R oldrel-1
* Windows Server, R release, R-devel and R oldrel-1

using `R CMD check --as-cran`.

## R CMD check results

0 errors | 0 warnings | 1 note

* checking installed package size ... NOTE
  installed size is ~40Mb (sub-directories `lib`, `include`, `libs`).

  rlibkriging bundles the 'libKriging' C++ library together with its C++
  dependencies (Armadillo and lbfgsb) as source and static libraries; the size
  comes entirely from these vendored components, as in the previous CRAN
  release. There is no run-time download.

## Reverse dependencies

There are no reverse dependencies on CRAN. <!-- please confirm before submitting -->
