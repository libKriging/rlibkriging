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

* local: Ubuntu 24.04, R 4.6.1
* GitHub Actions (`R CMD check --as-cran`): Ubuntu 24.04, macOS (Apple
  Silicon) and Windows Server, each with R release, R-devel and R oldrel-1

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Days since last update: 1

  This quick resubmission fixes the macOS R-devel installation failure of
  1.2-2 described above.

The installed package size is reported as INFO only: rlibkriging bundles the
'libKriging' C++ library and its C++ dependencies (Armadillo and lbfgsb) as
source and static libraries, as in the previous CRAN releases. There is no
run-time download.

## Reverse dependencies

We checked the one reverse dependency on CRAN, DiceView 4.0 (Suggests), with
`R CMD check` against this version: Status OK.
